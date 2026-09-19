classdef ImageClassificationApp < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                matlab.ui.Figure
        TitleLabel              matlab.ui.control.Label
        InputPanel              matlab.ui.container.Panel
        UitajmodelButton        matlab.ui.control.Button
        ModelLabel              matlab.ui.control.Label
        ModelNameLabel          matlab.ui.control.Label
        ModelInfoLabel          matlab.ui.control.Label
        UitajslikeButton        matlab.ui.control.Button
        ImagesInfoLabel         matlab.ui.control.Label
        KlasifikujButton        matlab.ui.control.Button
        PreviewPanel            matlab.ui.container.Panel
        UIAxes                  matlab.ui.control.UIAxes
        Top5Panel               matlab.ui.container.Panel
        Top5Table               matlab.ui.control.Table
        ResultsPanel            matlab.ui.container.Panel
        SummaryLabel            matlab.ui.control.Label
        ResultsTable            matlab.ui.control.Table
    end

    methods (Access = private)

        function name = displayName(~, className)
            % '02_Trouser' -> 'Trouser'; plain digit folders ('7') stay as they are
            name = regexprep(string(className), '^\d+_', '');
        end

        function showResult(app, idx)
            % Preview image idx and its top-5 breakdown
            results = app.UIFigure.UserData.Results;
            try
                imshow(imread(results.Files{idx}), 'Parent', app.UIAxes);
                [~, fname, ext] = fileparts(results.Files{idx});
                title(app.UIAxes, [fname ext], 'Interpreter', 'none');
            catch
                cla(app.UIAxes);
            end

            [sortedScores, order] = sort(results.Scores(idx, :), 'descend');
            n = min(5, numel(order));
            app.Top5Table.Data = table( ...
                (1:n)', ...
                displayName(app, results.Classes(order(1:n))), ...
                compose('%.2f%%', 100 * sortedScores(1:n))', ...
                'VariableNames', {'Rang', 'Klasa', 'Vjerovatnoća'});
        end
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            movegui(app.UIFigure, 'center');
        end

        % Button pushed function: UitajmodelButton
        function UitajmodelButtonPushed(app, event)
            % Otvori dijalog za odabir .mat fajla
            [file, path] = uigetfile('*.mat', 'Select Trained Model');
            if isequal(file,0)
                return; % korisnik je odustao
            end

            % Učitaj sadržaj fajla
            loadedData = load(fullfile(path, file));

            % Mreža: prvo 'net', inače prva SeriesNetwork/DAGNetwork promjenljiva
            model = [];
            if isfield(loadedData, 'net') && (isa(loadedData.net, 'SeriesNetwork') || isa(loadedData.net, 'DAGNetwork'))
                model = loadedData.net;
            else
                fn = fieldnames(loadedData);
                for k = 1:numel(fn)
                    candidate = loadedData.(fn{k});
                    if isa(candidate, 'SeriesNetwork') || isa(candidate, 'DAGNetwork')
                        model = candidate;
                        break;
                    end
                end
            end
            if isempty(model)
                uialert(app.UIFigure, 'Model fajl ne sadrži CNN mrežu (SeriesNetwork ili DAGNetwork)!', 'Greška');
                return;
            end

            % Imena klasa: redoslijed mora odgovarati kolonama score-a,
            % a to je redoslijed klasa u izlaznom sloju.
            modelClasses = string(model.Layers(end).Classes);
            if isfield(loadedData, 'classNames') && numel(loadedData.classNames) == numel(modelClasses)
                classNames = string(loadedData.classNames(:));
            else
                classNames = modelClasses(:);
            end

            % Sačuvaj mrežu u UserData za dalje korišćenje
            app.UIFigure.UserData.SelectedModel = model;
            app.UIFigure.UserData.ClassNames = classNames;
            app.UIFigure.UserData.Results = [];
            app.ModelNameLabel.Text = file;

            inputSize = model.Layers(1).InputSize;
            info = sprintf('Ulaz: %s  |  Klasa: %d', strjoin(string(inputSize), 'x'), numel(classNames));
            if isfield(loadedData, 'architecture')
                info = sprintf('%s: %s\n%s', 'Arhitektura', loadedData.architecture, info);
            end
            if isfield(loadedData, 'datasetName')
                info = sprintf('%s\nDataset: %s', info, loadedData.datasetName);
            end
            if isfield(loadedData, 'accuracy')
                info = sprintf('%s\nTest tačnost: %.2f%%', info, 100 * loadedData.accuracy);
            end
            app.ModelInfoLabel.Text = info;

            disp(['Model učitan: ', file]);
        end

        % Button pushed function: UitajslikeButton
        function UitajslikeButtonPushed(app, event)
            selection = questdlg('Testirate jednu sliku ili batch?', ...
                'Select Input', 'Jedna slika', 'Folder', 'Jedna slika');

            switch selection
                case 'Jedna slika'
                    [file, path] = uigetfile({'*.jpg;*.jpeg;*.png;*.bmp;*.tif;*.tiff', 'Slike'}, 'Select Image');
                    if isequal(file,0)
                        return;
                    end
                    fullFile = fullfile(path, file);
                    try
                        img = imread(fullFile);
                    catch
                        uialert(app.UIFigure, 'Odabrani fajl nije podržana slika!', 'Greška');
                        return;
                    end
                    app.UIFigure.UserData.TestImageFiles = {fullFile};
                    imshow(img, 'Parent', app.UIAxes);
                    title(app.UIAxes, file, 'Interpreter', 'none');
                    app.ImagesInfoLabel.Text = file;

                case 'Folder'
                    folder = uigetdir('', 'Select Image Folder');
                    if isequal(folder,0)
                        return;
                    end
                    imds = imageDatastore(folder, 'IncludeSubfolders', true, ...
                        'FileExtensions', {'.jpg', '.jpeg', '.png', '.bmp', '.tif', '.tiff'});

                    if isempty(imds.Files)
                        uialert(app.UIFigure, 'Nema validnih slika u folderu!', 'Greška');
                        return;
                    end

                    app.UIFigure.UserData.TestImageFiles = imds.Files;
                    app.ImagesInfoLabel.Text = sprintf('%d slika iz: %s', numel(imds.Files), folder);
                    imshow(imread(imds.Files{1}), 'Parent', app.UIAxes);
                    title(app.UIAxes, '');

                otherwise
                    return;
            end
            app.UIFigure.UserData.Results = [];
            app.ResultsTable.Data = {};
            app.Top5Table.Data = {};
            app.SummaryLabel.Text = '';
        end

        % Button pushed function: KlasifikujButton
        function KlasifikujButtonPushed(app, event)
            % Provera da li je model i slike učitan
            if isempty(app.UIFigure.UserData) || ...
               ~isfield(app.UIFigure.UserData, 'SelectedModel') || ...
               ~isfield(app.UIFigure.UserData, 'TestImageFiles') || ...
               isempty(app.UIFigure.UserData.SelectedModel) || ...
               isempty(app.UIFigure.UserData.TestImageFiles)
                uialert(app.UIFigure, 'Prvo učitaj model i slike!', 'Greška');
                return;
            end

            model = app.UIFigure.UserData.SelectedModel;
            classNames = app.UIFigure.UserData.ClassNames;
            imageFiles = app.UIFigure.UserData.TestImageFiles;
            inputSize = model.Layers(1).InputSize;

            % Resize + channel conversion in one datastore, classified in one call
            if inputSize(3) == 3
                colorPrep = 'gray2rgb';
            else
                colorPrep = 'rgb2gray';
            end
            imds = imageDatastore(imageFiles);
            augds = augmentedImageDatastore(inputSize(1:2), imds, 'ColorPreprocessing', colorPrep);

            app.KlasifikujButton.Enable = 'off';
            dlg = uiprogressdlg(app.UIFigure, 'Title', 'Klasifikacija', ...
                'Message', sprintf('Klasifikacija %d slika...', numel(imageFiles)), 'Indeterminate', 'on');
            try
                [labels, scores] = classify(model, augds, 'MiniBatchSize', 128);
            catch ME
                close(dlg);
                app.KlasifikujButton.Enable = 'on';
                uialert(app.UIFigure, sprintf('Greška tokom klasifikacije:\n%s', ME.message), 'Greška');
                return;
            end
            close(dlg);
            app.KlasifikujButton.Enable = 'on';

            % Klasa iz modela (ne iz imena fajla modela)
            predicted = string(labels);
            confidence = max(scores, [], 2);

            results.Files = imageFiles(:);
            results.Scores = scores;
            results.Classes = classNames;
            results.Predicted = predicted;
            app.UIFigure.UserData.Results = results;

            [folders, names, exts] = cellfun(@fileparts, results.Files, 'UniformOutput', false);
            app.ResultsTable.Data = table( ...
                string(names) + string(exts), ...
                displayName(app, predicted), ...
                compose('%.2f%%', 100 * confidence), ...
                'VariableNames', {'Fajl', 'Top-1 predikcija', 'Pouzdanost'});

            % Ako su slike u folderima nazvanim po klasama (npr. testing/02_Trouser), izračunaj tačnost
            [~, parentFolders] = cellfun(@fileparts, folders, 'UniformOutput', false);
            parentFolders = string(parentFolders);
            if all(ismember(parentFolders, classNames))
                acc = mean(parentFolders == predicted);
                app.SummaryLabel.Text = sprintf('Klasifikovano slika: %d  |  Tačnost (prema imenu foldera): %.2f%%', ...
                    numel(predicted), 100 * acc);
            else
                app.SummaryLabel.Text = sprintf('Klasifikovano slika: %d', numel(predicted));
            end

            showResult(app, 1);
        end

        % Cell selection callback: ResultsTable
        function ResultsTableCellSelection(app, event)
            if isempty(event.Indices) || ~isfield(app.UIFigure.UserData, 'Results') ...
                    || isempty(app.UIFigure.UserData.Results)
                return;
            end
            showResult(app, event.Indices(1, 1));
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 1200 760];
            app.UIFigure.Name = 'Klasifikacija slika';

            % Create TitleLabel
            app.TitleLabel = uilabel(app.UIFigure);
            app.TitleLabel.FontSize = 22;
            app.TitleLabel.FontWeight = 'bold';
            app.TitleLabel.Position = [24 704 800 32];
            app.TitleLabel.Text = 'Klasifikacija slika';

            %% Model i ulaz

            % Create InputPanel
            app.InputPanel = uipanel(app.UIFigure);
            app.InputPanel.Title = 'Model i ulaz';
            app.InputPanel.FontSize = 14;
            app.InputPanel.FontWeight = 'bold';
            app.InputPanel.Position = [24 344 372 340];

            % Create UitajmodelButton
            app.UitajmodelButton = uibutton(app.InputPanel, 'push');
            app.UitajmodelButton.ButtonPushedFcn = createCallbackFcn(app, @UitajmodelButtonPushed, true);
            app.UitajmodelButton.FontSize = 12;
            app.UitajmodelButton.Position = [16 270 160 36];
            app.UitajmodelButton.Text = 'Učitaj model';

            % Create ModelLabel
            app.ModelLabel = uilabel(app.InputPanel);
            app.ModelLabel.FontSize = 12;
            app.ModelLabel.Position = [16 236 50 24];
            app.ModelLabel.Text = 'Model:';

            % Create ModelNameLabel
            app.ModelNameLabel = uilabel(app.InputPanel);
            app.ModelNameLabel.FontName = 'Courier New';
            app.ModelNameLabel.FontSize = 11;
            app.ModelNameLabel.Position = [70 236 286 24];
            app.ModelNameLabel.Text = '';

            % Create ModelInfoLabel
            app.ModelInfoLabel = uilabel(app.InputPanel);
            app.ModelInfoLabel.FontSize = 12;
            app.ModelInfoLabel.WordWrap = 'on';
            app.ModelInfoLabel.VerticalAlignment = 'top';
            app.ModelInfoLabel.Position = [16 164 340 68];
            app.ModelInfoLabel.Text = '';

            % Create UitajslikeButton
            app.UitajslikeButton = uibutton(app.InputPanel, 'push');
            app.UitajslikeButton.ButtonPushedFcn = createCallbackFcn(app, @UitajslikeButtonPushed, true);
            app.UitajslikeButton.FontSize = 12;
            app.UitajslikeButton.Position = [16 116 160 36];
            app.UitajslikeButton.Text = 'Učitaj slike';

            % Create ImagesInfoLabel
            app.ImagesInfoLabel = uilabel(app.InputPanel);
            app.ImagesInfoLabel.FontName = 'Courier New';
            app.ImagesInfoLabel.FontSize = 11;
            app.ImagesInfoLabel.WordWrap = 'on';
            app.ImagesInfoLabel.VerticalAlignment = 'top';
            app.ImagesInfoLabel.Position = [16 72 340 36];
            app.ImagesInfoLabel.Text = '';

            % Create KlasifikujButton
            app.KlasifikujButton = uibutton(app.InputPanel, 'push');
            app.KlasifikujButton.ButtonPushedFcn = createCallbackFcn(app, @KlasifikujButtonPushed, true);
            app.KlasifikujButton.BackgroundColor = [0.20 0.45 0.75];
            app.KlasifikujButton.FontColor = [1 1 1];
            app.KlasifikujButton.FontSize = 13;
            app.KlasifikujButton.FontWeight = 'bold';
            app.KlasifikujButton.Position = [16 16 200 44];
            app.KlasifikujButton.Text = 'Klasifikuj';

            %% Pregled

            % Create PreviewPanel
            app.PreviewPanel = uipanel(app.UIFigure);
            app.PreviewPanel.Title = 'Pregled';
            app.PreviewPanel.FontSize = 14;
            app.PreviewPanel.FontWeight = 'bold';
            app.PreviewPanel.Position = [412 344 372 340];

            % Create UIAxes
            app.UIAxes = uiaxes(app.PreviewPanel);
            app.UIAxes.XTick = [];
            app.UIAxes.YTick = [];
            app.UIAxes.Position = [16 12 340 294];

            %% Top-5

            % Create Top5Panel
            app.Top5Panel = uipanel(app.UIFigure);
            app.Top5Panel.Title = 'Top-5 predikcije';
            app.Top5Panel.FontSize = 14;
            app.Top5Panel.FontWeight = 'bold';
            app.Top5Panel.Position = [800 344 376 340];

            % Create Top5Table
            app.Top5Table = uitable(app.Top5Panel);
            app.Top5Table.ColumnName = {'Rang'; 'Klasa'; 'Vjerovatnoća'};
            app.Top5Table.ColumnWidth = {50, 'auto', 110};
            app.Top5Table.RowName = {};
            app.Top5Table.FontSize = 12;
            app.Top5Table.Position = [16 16 344 290];

            %% Rezultati

            % Create ResultsPanel
            app.ResultsPanel = uipanel(app.UIFigure);
            app.ResultsPanel.Title = 'Rezultati';
            app.ResultsPanel.FontSize = 14;
            app.ResultsPanel.FontWeight = 'bold';
            app.ResultsPanel.Position = [24 24 1152 304];

            % Create SummaryLabel
            app.SummaryLabel = uilabel(app.ResultsPanel);
            app.SummaryLabel.FontSize = 13;
            app.SummaryLabel.Position = [16 246 1120 24];
            app.SummaryLabel.Text = '';

            % Create ResultsTable
            app.ResultsTable = uitable(app.ResultsPanel);
            app.ResultsTable.ColumnName = {'Fajl'; 'Top-1 predikcija'; 'Pouzdanost'};
            app.ResultsTable.ColumnWidth = {'auto', 300, 140};
            app.ResultsTable.RowName = {};
            app.ResultsTable.CellSelectionCallback = createCallbackFcn(app, @ResultsTableCellSelection, true);
            app.ResultsTable.FontSize = 12;
            app.ResultsTable.Position = [16 16 1120 222];

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = ImageClassificationApp

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
