classdef ImageGeneratingFromModel < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                matlab.ui.Figure
        TitleLabel              matlab.ui.control.Label
        ModelPanel              matlab.ui.container.Panel
        LoadModelButton         matlab.ui.control.Button
        ModelNameLabel          matlab.ui.control.Label
        ModelInfoLabel          matlab.ui.control.Label
        GeneratePanel           matlab.ui.container.Panel
        NumImagesLabel          matlab.ui.control.Label
        NumImagesEditField      matlab.ui.control.NumericEditField
        SeedLabel               matlab.ui.control.Label
        SeedEditField           matlab.ui.control.NumericEditField
        GenerateButton          matlab.ui.control.Button
        InterpStepsLabel        matlab.ui.control.Label
        InterpStepsSpinner      matlab.ui.control.Spinner
        InterpolateButton       matlab.ui.control.Button
        ManifoldButton          matlab.ui.control.Button
        LoadDatasetButton       matlab.ui.control.Button
        ReconstructButton       matlab.ui.control.Button
        DatasetPathLabel        matlab.ui.control.Label
        SavePngButton           matlab.ui.control.Button
        TabGroup                matlab.ui.container.TabGroup
        GenerationTab           matlab.ui.container.Tab
        GridAxes                matlab.ui.control.UIAxes
        InterpAxes              matlab.ui.control.UIAxes
        LatentTab               matlab.ui.container.Tab
        ManifoldAxes            matlab.ui.control.UIAxes
        ReconAxes               matlab.ui.control.UIAxes
        EvalTab                 matlab.ui.container.Tab
        LoadClassifierButton    matlab.ui.control.Button
        ClassifierNameLabel     matlab.ui.control.Label
        EvalNumLabel            matlab.ui.control.Label
        EvalNumEditField        matlab.ui.control.NumericEditField
        EvaluateButton          matlab.ui.control.Button
        WarningLabel            matlab.ui.control.Label
        ConfCaptionLabel        matlab.ui.control.Label
        ConfValueLabel          matlab.ui.control.Label
        ISCaptionLabel          matlab.ui.control.Label
        ISValueLabel            matlab.ui.control.Label
        HistAxes                matlab.ui.control.UIAxes
    end

    properties (Access = private)
        Model                   % validated VAE struct (loadVaeModel)
        LastGrid                % last generated grid, uint8 image
        DatasetPath = ''
        TestFiles = {}          % testing/ images of the chosen dataset
        Classifier              % struct: net, fileName, datasetName, architecture
    end

    methods (Access = private)

        function names = displayName(~, classNames)
            % '02_Trouser' -> 'Trouser'; plain digit folders ('7') stay as they are
            names = regexprep(string(classNames), '^\d+_', '');
        end

        function tf = requireModel(app)
            % Guard clause shared by every action that needs a loaded VAE
            tf = ~isempty(app.Model);
            if ~tf
                uialert(app.UIFigure, 'Morate učitati model prvo!', 'Warning');
            end
        end

        function updateDatasetWarning(app)
            % Warn when the classifier was trained on another dataset than the VAE
            app.WarningLabel.Text = '';
            if isempty(app.Model) || isempty(app.Classifier)
                return;
            end
            if strlength(app.Classifier.datasetName) == 0
                app.WarningLabel.Text = 'Upozorenje: dataset klasifikatora nije poznat, rezultati možda nisu smisleni.';
            elseif ~strcmp(app.Classifier.datasetName, string(app.Model.datasetName))
                app.WarningLabel.Text = sprintf( ...
                    'Upozorenje: klasifikator je treniran na datasetu "%s", a VAE na "%s". Rezultati možda nisu smisleni.', ...
                    app.Classifier.datasetName, string(app.Model.datasetName));
            end
        end

    end

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            movegui(app.UIFigure, 'center');
            title(app.GridAxes, 'Generisane slike');
            title(app.InterpAxes, 'Latentna interpolacija');
            title(app.ManifoldAxes, 'Latentni manifold');
            title(app.ReconAxes, 'Original (gore) i rekonstrukcija (dolje)');
            title(app.HistAxes, 'Predviđene klase generisanih slika');
            xlabel(app.HistAxes, 'Klasa');
            ylabel(app.HistAxes, 'Broj slika');
        end

        % Button pushed function: LoadModelButton
        function LoadModelButtonPushed(app, event)
            [file, path] = uigetfile('*.mat', 'Izaberi VAE model');
            if isequal(file, 0)
                figure(app.UIFigure);
                return;
            end
            try
                model = loadVaeModel(fullfile(path, file));
            catch ME
                uialert(app.UIFigure, ME.message, 'Greška');
                return;
            end

            app.Model = model;
            app.LastGrid = [];
            app.DatasetPath = '';
            app.TestFiles = {};
            app.DatasetPathLabel.Text = '';
            app.ModelNameLabel.Text = file;

            info = sprintf('Latentna dimenzija: %d  |  Slika: %dx%dx%d\nDataset: %s', ...
                model.latentDim, model.imageSize(1), model.imageSize(2), model.channels, string(model.datasetName));
            if isfield(model, 'reconLossType') && isfield(model, 'beta')
                info = sprintf('%s\nGubitak: %s, β = %g', info, string(model.reconLossType), model.beta);
            end
            if isfield(model, 'epochsCompleted')
                info = sprintf('%s\nEpohe: %d', info, model.epochsCompleted);
            end
            app.ModelInfoLabel.Text = info;

            if model.latentDim == 2
                app.ManifoldButton.Enable = 'on';
            else
                app.ManifoldButton.Enable = 'off';
            end

            cla(app.GridAxes);
            cla(app.InterpAxes);
            cla(app.ManifoldAxes);
            cla(app.ReconAxes);
            updateDatasetWarning(app);
        end

        % Button pushed function: GenerateButton
        function GenerateButtonPushed(app, event)
            if ~requireModel(app)
                return;
            end
            n = app.NumImagesEditField.Value;
            seed = app.SeedEditField.Value;
            imgs = generateImages(app.Model, n, seed);
            app.LastGrid = sampleGridImage(imgs);
            imshow(app.LastGrid, 'Parent', app.GridAxes);
            title(app.GridAxes, sprintf('%d generisanih slika (seed %d)', n, seed));
            app.TabGroup.SelectedTab = app.GenerationTab;
        end

        % Button pushed function: InterpolateButton
        function InterpolateButtonPushed(app, event)
            if ~requireModel(app)
                return;
            end
            steps = app.InterpStepsSpinner.Value;
            seed = app.SeedEditField.Value;
            imgs = latentInterpolation(app.Model, steps, seed);
            imshow(sampleGridImage(imgs, [1 steps]), 'Parent', app.InterpAxes);
            title(app.InterpAxes, sprintf('Latentna interpolacija, %d koraka (seed %d)', steps, seed));
            app.TabGroup.SelectedTab = app.GenerationTab;
        end

        % Button pushed function: ManifoldButton
        function ManifoldButtonPushed(app, event)
            if ~requireModel(app)
                return;
            end
            if app.Model.latentDim ~= 2
                uialert(app.UIFigure, 'Latentni manifold je dostupan samo za latentDim = 2.', 'Warning');
                return;
            end
            tile = latentManifold(app.Model, 15, 3);
            if size(tile, 3) == 1
                tile = repmat(tile, 1, 1, 3);
            end
            ax = app.ManifoldAxes;
            cla(ax);
            % Row 1 of the tile is z2 = +3, so flip it to draw it at the top of a normal y axis
            image(ax, 'XData', [-3 3], 'YData', [-3 3], 'CData', flipud(tile));
            ax.YDir = 'normal';
            axis(ax, 'image');
            xlabel(ax, 'z_1');
            ylabel(ax, 'z_2');
            title(ax, 'Latentni manifold [-3, 3]^2');
            app.TabGroup.SelectedTab = app.LatentTab;
        end

        % Button pushed function: LoadDatasetButton
        function LoadDatasetButtonPushed(app, event)
            if ~requireModel(app)
                return;
            end
            startPath = fullfile(pwd, 'datasets');
            if ~isfolder(startPath)
                startPath = pwd;
            end
            folder = uigetdir(startPath, 'Izaberi dataset folder');
            if isequal(folder, 0)
                figure(app.UIFigure);
                return;
            end
            manifestFile = fullfile(folder, 'photolab_dataset.mat');
            if ~isfile(manifestFile)
                uialert(app.UIFigure, ...
                    'Folder ne sadrži photolab_dataset.mat. Izaberite dataset pripremljen u PhotoLab-u.', 'Greška');
                return;
            end
            manifest = load(manifestFile);
            if ~isequal(manifest.imageSize(1:2), app.Model.imageSize(1:2)) || manifest.channels ~= app.Model.channels
                uialert(app.UIFigure, sprintf( ...
                    'Dataset (%dx%dx%d) ne odgovara modelu (%dx%dx%d).', ...
                    manifest.imageSize(1), manifest.imageSize(2), manifest.channels, ...
                    app.Model.imageSize(1), app.Model.imageSize(2), app.Model.channels), 'Greška');
                return;
            end
            testDir = fullfile(folder, 'testing');
            if ~isfolder(testDir)
                uialert(app.UIFigure, 'Dataset nema folder "testing".', 'Greška');
                return;
            end
            imds = imageDatastore(testDir, 'IncludeSubfolders', true);
            if isempty(imds.Files)
                uialert(app.UIFigure, 'Folder "testing" ne sadrži slike.', 'Greška');
                return;
            end
            app.TestFiles = imds.Files;
            app.DatasetPath = folder;
            app.DatasetPathLabel.Text = folder;
        end

        % Button pushed function: ReconstructButton
        function ReconstructButtonPushed(app, event)
            if ~requireModel(app)
                return;
            end
            if isempty(app.TestFiles)
                uialert(app.UIFigure, 'Morate izabrati dataset prvo!', 'Warning');
                return;
            end
            n = 8;
            idx = randperm(numel(app.TestFiles), min(n, numel(app.TestFiles)));
            n = numel(idx);
            imageSize = app.Model.imageSize(1:2);
            X = zeros([imageSize app.Model.channels n], 'single');
            try
                for k = 1:n
                    X(:, :, :, k) = readVaeImage(app.TestFiles{idx(k)}, imageSize, app.Model.channels);
                end
                recon = reconstructImages(app.Model, X);
            catch ME
                uialert(app.UIFigure, ME.message, 'Greška');
                return;
            end
            tile = sampleGridImage(cat(4, im2uint8(X), im2uint8(recon)), [2 n]);
            imshow(tile, 'Parent', app.ReconAxes);
            title(app.ReconAxes, 'Original (gore) i rekonstrukcija (dolje)');
            app.TabGroup.SelectedTab = app.LatentTab;
        end

        % Button pushed function: SavePngButton
        function SavePngButtonPushed(app, event)
            if isempty(app.LastGrid)
                uialert(app.UIFigure, 'Morate generisati slike prvo!', 'Warning');
                return;
            end
            [file, path] = uiputfile('generisane_slike.png', 'Sačuvaj grid slika');
            if isequal(file, 0)
                figure(app.UIFigure);
                return;
            end
            try
                imwrite(app.LastGrid, fullfile(path, file));
            catch ME
                uialert(app.UIFigure, ME.message, 'Greška');
            end
        end

        % Button pushed function: LoadClassifierButton
        function LoadClassifierButtonPushed(app, event)
            [file, path] = uigetfile('*.mat', 'Izaberi klasifikator treniran u PhotoLab-u');
            if isequal(file, 0)
                figure(app.UIFigure);
                return;
            end
            loadedData = load(fullfile(path, file));

            net = [];
            if isfield(loadedData, 'net') && (isa(loadedData.net, 'SeriesNetwork') || isa(loadedData.net, 'DAGNetwork'))
                net = loadedData.net;
            end
            if isempty(net)
                uialert(app.UIFigure, 'Fajl ne sadrži CNN klasifikator (SeriesNetwork ili DAGNetwork)!', 'Greška');
                return;
            end

            datasetName = "";
            if isfield(loadedData, 'datasetName')
                datasetName = string(loadedData.datasetName);
            end
            architecture = "?";
            if isfield(loadedData, 'architecture')
                architecture = string(loadedData.architecture);
            end
            app.Classifier = struct('net', net, 'fileName', file, ...
                'datasetName', datasetName, 'architecture', architecture);
            app.ClassifierNameLabel.Text = sprintf('%s  |  %s  |  %s', file, architecture, datasetName);
            updateDatasetWarning(app);
        end

        % Button pushed function: EvaluateButton
        function EvaluateButtonPushed(app, event)
            if ~requireModel(app)
                return;
            end
            if isempty(app.Classifier)
                uialert(app.UIFigure, 'Morate učitati klasifikator prvo!', 'Warning');
                return;
            end
            updateDatasetWarning(app);

            n = app.EvalNumEditField.Value;
            app.EvaluateButton.Enable = 'off';
            dlg = uiprogressdlg(app.UIFigure, 'Title', 'Evaluacija', ...
                'Message', sprintf('Generisanje i klasifikacija %d slika...', n), 'Indeterminate', 'on');
            try
                result = evaluateWithClassifier(app.Model, app.Classifier.net, n, app.SeedEditField.Value);
            catch ME
                close(dlg);
                app.EvaluateButton.Enable = 'on';
                uialert(app.UIFigure, sprintf('Greška tokom evaluacije:\n%s', ME.message), 'Greška');
                return;
            end
            close(dlg);
            app.EvaluateButton.Enable = 'on';

            numClasses = numel(result.classNames);
            ax = app.HistAxes;
            cla(ax);
            bar(ax, 1:numClasses, result.classCounts);
            if numClasses <= 20
                xticks(ax, 1:numClasses);
                xticklabels(ax, displayName(app, result.classNames));
            else
                xticks(ax, []);
            end
            xlabel(ax, 'Klasa');
            ylabel(ax, 'Broj slika');
            title(ax, sprintf('Predviđene klase generisanih slika (N = %d)', result.numImages));

            app.ConfValueLabel.Text = sprintf('%.1f%%', 100 * result.meanConfidence);
            app.ISValueLabel.Text = sprintf('%.2f  (maks. %d)', result.inceptionScore, numClasses);
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 1200 760];
            app.UIFigure.Name = 'Generisanje slika';

            % Create TitleLabel
            app.TitleLabel = uilabel(app.UIFigure);
            app.TitleLabel.FontSize = 22;
            app.TitleLabel.FontWeight = 'bold';
            app.TitleLabel.Position = [24 704 800 32];
            app.TitleLabel.Text = 'Generisanje slika';

            %% Model

            % Create ModelPanel
            app.ModelPanel = uipanel(app.UIFigure);
            app.ModelPanel.Title = 'Model';
            app.ModelPanel.FontSize = 14;
            app.ModelPanel.FontWeight = 'bold';
            app.ModelPanel.Position = [24 512 372 172];

            % Create LoadModelButton
            app.LoadModelButton = uibutton(app.ModelPanel, 'push');
            app.LoadModelButton.ButtonPushedFcn = createCallbackFcn(app, @LoadModelButtonPushed, true);
            app.LoadModelButton.FontSize = 12;
            app.LoadModelButton.Position = [16 106 160 36];
            app.LoadModelButton.Text = 'Učitaj VAE model';

            % Create ModelNameLabel
            app.ModelNameLabel = uilabel(app.ModelPanel);
            app.ModelNameLabel.FontName = 'Courier New';
            app.ModelNameLabel.FontSize = 11;
            app.ModelNameLabel.Position = [16 78 340 22];
            app.ModelNameLabel.Text = '';

            % Create ModelInfoLabel
            app.ModelInfoLabel = uilabel(app.ModelPanel);
            app.ModelInfoLabel.FontSize = 12;
            app.ModelInfoLabel.WordWrap = 'on';
            app.ModelInfoLabel.VerticalAlignment = 'top';
            app.ModelInfoLabel.Position = [16 8 340 66];
            app.ModelInfoLabel.Text = '';

            %% Generisanje

            % Create GeneratePanel
            app.GeneratePanel = uipanel(app.UIFigure);
            app.GeneratePanel.Title = 'Generisanje';
            app.GeneratePanel.FontSize = 14;
            app.GeneratePanel.FontWeight = 'bold';
            app.GeneratePanel.Position = [24 24 372 472];

            % Create NumImagesLabel
            app.NumImagesLabel = uilabel(app.GeneratePanel);
            app.NumImagesLabel.FontSize = 12;
            app.NumImagesLabel.Position = [16 398 176 24];
            app.NumImagesLabel.Text = 'Broj slika';

            % Create NumImagesEditField
            app.NumImagesEditField = uieditfield(app.GeneratePanel, 'numeric');
            app.NumImagesEditField.Limits = [1 400];
            app.NumImagesEditField.RoundFractionalValues = 'on';
            app.NumImagesEditField.ValueDisplayFormat = '%d';
            app.NumImagesEditField.FontSize = 12;
            app.NumImagesEditField.Position = [200 398 140 24];
            app.NumImagesEditField.Value = 25;

            % Create SeedLabel
            app.SeedLabel = uilabel(app.GeneratePanel);
            app.SeedLabel.FontSize = 12;
            app.SeedLabel.Position = [16 362 176 24];
            app.SeedLabel.Text = 'Seed';

            % Create SeedEditField
            app.SeedEditField = uieditfield(app.GeneratePanel, 'numeric');
            app.SeedEditField.Limits = [0 1000000000];
            app.SeedEditField.RoundFractionalValues = 'on';
            app.SeedEditField.ValueDisplayFormat = '%d';
            app.SeedEditField.FontSize = 12;
            app.SeedEditField.Position = [200 362 140 24];
            app.SeedEditField.Value = 1;

            % Create GenerateButton
            app.GenerateButton = uibutton(app.GeneratePanel, 'push');
            app.GenerateButton.ButtonPushedFcn = createCallbackFcn(app, @GenerateButtonPushed, true);
            app.GenerateButton.BackgroundColor = [0.20 0.45 0.75];
            app.GenerateButton.FontColor = [1 1 1];
            app.GenerateButton.FontSize = 13;
            app.GenerateButton.FontWeight = 'bold';
            app.GenerateButton.Position = [16 306 200 44];
            app.GenerateButton.Text = 'Generiši';

            % Create InterpStepsLabel
            app.InterpStepsLabel = uilabel(app.GeneratePanel);
            app.InterpStepsLabel.FontSize = 12;
            app.InterpStepsLabel.Position = [16 270 176 24];
            app.InterpStepsLabel.Text = 'Koraka interpolacije';

            % Create InterpStepsSpinner
            app.InterpStepsSpinner = uispinner(app.GeneratePanel);
            app.InterpStepsSpinner.Limits = [2 20];
            app.InterpStepsSpinner.RoundFractionalValues = 'on';
            app.InterpStepsSpinner.FontSize = 12;
            app.InterpStepsSpinner.Position = [200 270 140 24];
            app.InterpStepsSpinner.Value = 10;

            % Create InterpolateButton
            app.InterpolateButton = uibutton(app.GeneratePanel, 'push');
            app.InterpolateButton.ButtonPushedFcn = createCallbackFcn(app, @InterpolateButtonPushed, true);
            app.InterpolateButton.FontSize = 12;
            app.InterpolateButton.Position = [16 222 160 36];
            app.InterpolateButton.Text = 'Interpolacija';

            % Create ManifoldButton
            app.ManifoldButton = uibutton(app.GeneratePanel, 'push');
            app.ManifoldButton.ButtonPushedFcn = createCallbackFcn(app, @ManifoldButtonPushed, true);
            app.ManifoldButton.FontSize = 12;
            app.ManifoldButton.Enable = 'off';
            app.ManifoldButton.Position = [196 222 160 36];
            app.ManifoldButton.Text = 'Latentni manifold';

            % Create LoadDatasetButton
            app.LoadDatasetButton = uibutton(app.GeneratePanel, 'push');
            app.LoadDatasetButton.ButtonPushedFcn = createCallbackFcn(app, @LoadDatasetButtonPushed, true);
            app.LoadDatasetButton.FontSize = 12;
            app.LoadDatasetButton.Position = [16 170 160 36];
            app.LoadDatasetButton.Text = 'Učitaj dataset';

            % Create ReconstructButton
            app.ReconstructButton = uibutton(app.GeneratePanel, 'push');
            app.ReconstructButton.ButtonPushedFcn = createCallbackFcn(app, @ReconstructButtonPushed, true);
            app.ReconstructButton.FontSize = 12;
            app.ReconstructButton.Position = [196 170 160 36];
            app.ReconstructButton.Text = 'Rekonstrukcija';

            % Create DatasetPathLabel
            app.DatasetPathLabel = uilabel(app.GeneratePanel);
            app.DatasetPathLabel.FontName = 'Courier New';
            app.DatasetPathLabel.FontSize = 11;
            app.DatasetPathLabel.WordWrap = 'on';
            app.DatasetPathLabel.VerticalAlignment = 'top';
            app.DatasetPathLabel.Position = [16 118 340 44];
            app.DatasetPathLabel.Text = '';

            % Create SavePngButton
            app.SavePngButton = uibutton(app.GeneratePanel, 'push');
            app.SavePngButton.ButtonPushedFcn = createCallbackFcn(app, @SavePngButtonPushed, true);
            app.SavePngButton.FontSize = 12;
            app.SavePngButton.Position = [16 66 160 36];
            app.SavePngButton.Text = 'Sačuvaj grid (PNG)';

            %% Desna strana: tabovi

            % Create TabGroup
            app.TabGroup = uitabgroup(app.UIFigure);
            app.TabGroup.Position = [412 24 764 660];

            % Create GenerationTab
            app.GenerationTab = uitab(app.TabGroup);
            app.GenerationTab.Title = 'Generisanje';

            % Create GridAxes
            app.GridAxes = uiaxes(app.GenerationTab);
            app.GridAxes.XTick = [];
            app.GridAxes.YTick = [];
            app.GridAxes.Position = [16 176 728 432];

            % Create InterpAxes
            app.InterpAxes = uiaxes(app.GenerationTab);
            app.InterpAxes.XTick = [];
            app.InterpAxes.YTick = [];
            app.InterpAxes.Position = [16 16 728 144];

            % Create LatentTab
            app.LatentTab = uitab(app.TabGroup);
            app.LatentTab.Title = 'Latentni prostor';

            % Create ManifoldAxes
            app.ManifoldAxes = uiaxes(app.LatentTab);
            app.ManifoldAxes.Position = [16 196 728 412];

            % Create ReconAxes
            app.ReconAxes = uiaxes(app.LatentTab);
            app.ReconAxes.XTick = [];
            app.ReconAxes.YTick = [];
            app.ReconAxes.Position = [16 16 728 164];

            % Create EvalTab
            app.EvalTab = uitab(app.TabGroup);
            app.EvalTab.Title = 'Evaluacija klasifikatorom';

            % Create LoadClassifierButton
            app.LoadClassifierButton = uibutton(app.EvalTab, 'push');
            app.LoadClassifierButton.ButtonPushedFcn = createCallbackFcn(app, @LoadClassifierButtonPushed, true);
            app.LoadClassifierButton.FontSize = 12;
            app.LoadClassifierButton.Position = [16 566 160 36];
            app.LoadClassifierButton.Text = 'Učitaj klasifikator';

            % Create ClassifierNameLabel
            app.ClassifierNameLabel = uilabel(app.EvalTab);
            app.ClassifierNameLabel.FontName = 'Courier New';
            app.ClassifierNameLabel.FontSize = 11;
            app.ClassifierNameLabel.Position = [188 572 556 24];
            app.ClassifierNameLabel.Text = '';

            % Create EvalNumLabel
            app.EvalNumLabel = uilabel(app.EvalTab);
            app.EvalNumLabel.FontSize = 12;
            app.EvalNumLabel.Position = [16 526 90 24];
            app.EvalNumLabel.Text = 'Broj slika:';

            % Create EvalNumEditField
            app.EvalNumEditField = uieditfield(app.EvalTab, 'numeric');
            app.EvalNumEditField.Limits = [1 20000];
            app.EvalNumEditField.RoundFractionalValues = 'on';
            app.EvalNumEditField.ValueDisplayFormat = '%d';
            app.EvalNumEditField.FontSize = 12;
            app.EvalNumEditField.Position = [110 526 90 24];
            app.EvalNumEditField.Value = 1000;

            % Create EvaluateButton
            app.EvaluateButton = uibutton(app.EvalTab, 'push');
            app.EvaluateButton.ButtonPushedFcn = createCallbackFcn(app, @EvaluateButtonPushed, true);
            app.EvaluateButton.FontSize = 12;
            app.EvaluateButton.Position = [216 520 160 36];
            app.EvaluateButton.Text = 'Evaluiraj';

            % Create WarningLabel
            app.WarningLabel = uilabel(app.EvalTab);
            app.WarningLabel.FontSize = 12;
            app.WarningLabel.FontWeight = 'bold';
            app.WarningLabel.FontColor = [0.85 0.33 0.10];
            app.WarningLabel.Position = [16 484 728 24];
            app.WarningLabel.Text = '';

            % Create ConfCaptionLabel
            app.ConfCaptionLabel = uilabel(app.EvalTab);
            app.ConfCaptionLabel.FontSize = 12;
            app.ConfCaptionLabel.Position = [16 436 340 22];
            app.ConfCaptionLabel.Text = 'Prosječna max-softmax pouzdanost';

            % Create ConfValueLabel
            app.ConfValueLabel = uilabel(app.EvalTab);
            app.ConfValueLabel.FontSize = 20;
            app.ConfValueLabel.FontWeight = 'bold';
            app.ConfValueLabel.FontColor = [0.18 0.55 0.34];
            app.ConfValueLabel.Position = [16 400 340 32];
            app.ConfValueLabel.Text = '—';

            % Create ISCaptionLabel
            app.ISCaptionLabel = uilabel(app.EvalTab);
            app.ISCaptionLabel.FontSize = 12;
            app.ISCaptionLabel.Position = [392 436 352 22];
            app.ISCaptionLabel.Text = 'Inception Score (pojednostavljen)';

            % Create ISValueLabel
            app.ISValueLabel = uilabel(app.EvalTab);
            app.ISValueLabel.FontSize = 20;
            app.ISValueLabel.FontWeight = 'bold';
            app.ISValueLabel.FontColor = [0.18 0.55 0.34];
            app.ISValueLabel.Position = [392 400 352 32];
            app.ISValueLabel.Text = '—';

            % Create HistAxes
            app.HistAxes = uiaxes(app.EvalTab);
            app.HistAxes.Position = [16 16 728 366];

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = ImageGeneratingFromModel

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end
