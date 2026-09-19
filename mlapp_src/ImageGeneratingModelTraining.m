classdef ImageGeneratingModelTraining < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                matlab.ui.Figure
        TitleLabel              matlab.ui.control.Label
        StatusLabel             matlab.ui.control.Label
        DatasetPanel            matlab.ui.container.Panel
        SelectDatasetButton     matlab.ui.control.Button
        DatasetPathLabel        matlab.ui.control.Label
        DatasetInfoLabel        matlab.ui.control.Label
        ParamsPanel             matlab.ui.container.Panel
        CommonSectionLabel      matlab.ui.control.Label
        LatentDimLabel          matlab.ui.control.Label
        LatentDimSpinner        matlab.ui.control.Spinner
        EpochsLabel             matlab.ui.control.Label
        EpochsSpinner           matlab.ui.control.Spinner
        BatchSizeLabel          matlab.ui.control.Label
        BatchSizeEditField      matlab.ui.control.NumericEditField
        LearnRateLabel          matlab.ui.control.Label
        LearnRateEditField      matlab.ui.control.NumericEditField
        SeedLabel               matlab.ui.control.Label
        SeedEditField           matlab.ui.control.NumericEditField
        MaxImagesLabel          matlab.ui.control.Label
        MaxImagesEditField      matlab.ui.control.NumericEditField
        VaeSectionLabel         matlab.ui.control.Label
        BetaLabel               matlab.ui.control.Label
        BetaEditField           matlab.ui.control.NumericEditField
        ReconLossLabel          matlab.ui.control.Label
        ReconLossDropDown       matlab.ui.control.DropDown
        StopButton              matlab.ui.control.Button
        StartTrainingButton     matlab.ui.control.Button
        LossPanel               matlab.ui.container.Panel
        TotalLossAxes           matlab.ui.control.UIAxes
        ReconLossAxes           matlab.ui.control.UIAxes
        KLLossAxes              matlab.ui.control.UIAxes
        SamplesPanel            matlab.ui.container.Panel
        SamplesAxes             matlab.ui.control.UIAxes
    end

    properties (Access = private)
        DatasetPath = ''
        IsTraining = false
        StopRequested = false
    end

    methods (Access = private)

        function setBusy(app, isBusy, statusText)
            % Lock the inputs while training runs; only Zaustavi stays usable
            if isBusy
                state = 'off';
                stopState = 'on';
            else
                state = 'on';
                stopState = 'off';
            end
            controls = [app.DatasetPanel.Children; app.ParamsPanel.Children];
            for k = 1:numel(controls)
                if isprop(controls(k), 'Enable')
                    controls(k).Enable = state;
                end
            end
            app.StopButton.Enable = stopState;
            app.StatusLabel.Text = "Status: " + statusText;
            drawnow;
        end

        function p = collectParams(app)
            % Read every training control into one struct for trainGenerativeModel
            p.latentDim = app.LatentDimSpinner.Value;
            p.epochs = app.EpochsSpinner.Value;
            p.batchSize = app.BatchSizeEditField.Value;
            p.learnRate = app.LearnRateEditField.Value;
            p.seed = app.SeedEditField.Value;
            p.maxImages = app.MaxImagesEditField.Value;
            p.beta = app.BetaEditField.Value;
            p.reconLossType = app.ReconLossDropDown.Value;
        end

        function plotLoss(~, ax, values, titleText)
            % Plot one loss curve; title and labels are set after plotting so they survive
            plot(ax, 1:numel(values), values, '-o', 'LineWidth', 1.5, 'MarkerSize', 4);
            title(ax, titleText);
            xlabel(ax, 'Epoha');
            grid(ax, 'on');
        end

        function stop = onProgress(app, info)
            % Called by trainGenerativeModel while loading and after every epoch
            stop = false;
            if info.phase == "loading"
                app.StatusLabel.Text = sprintf('Status: učitavanje slika... %d%%', round(100 * info.fraction));
                drawnow limitrate;
                return;
            end

            plotLoss(app, app.TotalLossAxes, info.history.total, 'Ukupni gubitak');
            plotLoss(app, app.ReconLossAxes, info.history.recon, 'Rekonstrukcija');
            plotLoss(app, app.KLLossAxes, info.history.kl, 'KL divergencija');

            imshow(info.sampleGrid, 'Parent', app.SamplesAxes);
            title(app.SamplesAxes, sprintf('Epoha %d / %d', info.epoch, info.epochs));

            app.StatusLabel.Text = sprintf('Status: epoha %d / %d  |  gubitak %.2f  |  %s', ...
                info.epoch, info.epochs, info.loss, char(duration(0, 0, info.elapsed, 'Format', 'hh:mm:ss')));
            drawnow;      % also lets a click on Zaustavi through
            stop = app.StopRequested;
        end
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            movegui(app.UIFigure, 'center');
            title(app.TotalLossAxes, 'Ukupni gubitak');
            xlabel(app.TotalLossAxes, 'Epoha');
            title(app.ReconLossAxes, 'Rekonstrukcija');
            xlabel(app.ReconLossAxes, 'Epoha');
            title(app.KLLossAxes, 'KL divergencija');
            xlabel(app.KLLossAxes, 'Epoha');
        end

        % Button pushed function: SelectDatasetButton
        function SelectDatasetButtonPushed(app, event)
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
            imageSize = manifest.imageSize(1:2);
            channels = manifest.channels;
            if ~(isequal(imageSize, [28 28]) || isequal(imageSize, [32 32])) || ~any(channels == [1 3])
                uialert(app.UIFigure, sprintf( ...
                    'Podržane su slike 28x28 i 32x32 sa 1 ili 3 kanala (dataset: %dx%dx%d).', ...
                    imageSize(1), imageSize(2), channels), 'Greška');
                return;
            end
            if ~isfolder(fullfile(folder, 'training'))
                uialert(app.UIFigure, 'Dataset nema folder "training".', 'Greška');
                return;
            end

            app.DatasetPath = folder;
            app.DatasetPathLabel.Text = folder;
            app.DatasetInfoLabel.Text = sprintf('Slika: %dx%dx%d  |  Klasa: %d', ...
                imageSize(1), imageSize(2), channels, numel(manifest.classNames));
            % BCE suits grayscale data, MSE colour data (the user can still change it)
            if channels == 1
                app.ReconLossDropDown.Value = 'BCE';
            else
                app.ReconLossDropDown.Value = 'MSE';
            end
        end

        % Button pushed function: StartTrainingButton
        function StartTrainingButtonPushed(app, event)
            if isempty(app.DatasetPath)
                uialert(app.UIFigure, 'Morate izabrati dataset prvo!', 'Warning');
                return;
            end
            p = collectParams(app);

            % Choose where to save before training starts
            [~, datasetName] = fileparts(app.DatasetPath);
            defaultName = regexprep(sprintf('VAE_%s.mat', datasetName), '[^\w.]', '_');
            [file, path] = uiputfile(defaultName, 'Sačuvaj VAE model kao');
            if isequal(file, 0)
                uialert(app.UIFigure, 'Treniranje otkazano. Fajl nije izabran.', 'Otkazano');
                return;
            end
            savePath = fullfile(path, file);

            cla(app.TotalLossAxes);
            cla(app.ReconLossAxes);
            cla(app.KLLossAxes);
            cla(app.SamplesAxes);
            app.StopRequested = false;
            app.IsTraining = true;
            setBusy(app, true, 'učitavanje slika...');

            try
                model = trainGenerativeModel(p, app.DatasetPath, @(info) onProgress(app, info));
                save(savePath, '-struct', 'model');
            catch ME
                app.IsTraining = false;
                setBusy(app, false, 'Greška tokom treniranja');
                uialert(app.UIFigure, ME.message, 'Greška');
                return;
            end
            app.IsTraining = false;

            if model.epochsCompleted < model.epochs
                status = 'zaustavljeno, model sačuvan';
                message = sprintf('Treniranje zaustavljeno nakon %d od %d epoha. Model sačuvan.', ...
                    model.epochsCompleted, model.epochs);
            else
                status = 'treniranje završeno, model sačuvan';
                message = 'Treniranje završeno i model sačuvan.';
            end
            setBusy(app, false, status);
            uialert(app.UIFigure, message, 'Uspjeh', 'Icon', 'success');
        end

        % Button pushed function: StopButton
        function StopButtonPushed(app, event)
            app.StopRequested = true;
            app.StopButton.Enable = 'off';
            app.StatusLabel.Text = 'Status: zaustavljanje nakon trenutne epohe...';
        end

        % Close request function: UIFigure
        function UIFigureCloseRequest(app, event)
            if app.IsTraining
                app.StopRequested = true;
                uialert(app.UIFigure, ...
                    'Treniranje je u toku i zaustavlja se nakon trenutne epohe. Zatvorite prozor kada se završi.', 'Warning');
                return;
            end
            delete(app);
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 1200 760];
            app.UIFigure.Name = 'Treniranje generativnog modela';
            app.UIFigure.CloseRequestFcn = createCallbackFcn(app, @UIFigureCloseRequest, true);

            % Create TitleLabel
            app.TitleLabel = uilabel(app.UIFigure);
            app.TitleLabel.FontSize = 22;
            app.TitleLabel.FontWeight = 'bold';
            app.TitleLabel.Position = [24 704 380 32];
            app.TitleLabel.Text = 'Treniranje generativnog modela';

            % Create StatusLabel
            app.StatusLabel = uilabel(app.UIFigure);
            app.StatusLabel.FontSize = 12;
            app.StatusLabel.HorizontalAlignment = 'right';
            app.StatusLabel.Position = [420 708 756 24];
            app.StatusLabel.Text = 'Status: spremno';

            %% Dataset

            % Create DatasetPanel
            app.DatasetPanel = uipanel(app.UIFigure);
            app.DatasetPanel.Title = 'Dataset';
            app.DatasetPanel.FontSize = 14;
            app.DatasetPanel.FontWeight = 'bold';
            app.DatasetPanel.Position = [24 544 372 140];

            % Create SelectDatasetButton
            app.SelectDatasetButton = uibutton(app.DatasetPanel, 'push');
            app.SelectDatasetButton.ButtonPushedFcn = createCallbackFcn(app, @SelectDatasetButtonPushed, true);
            app.SelectDatasetButton.FontSize = 12;
            app.SelectDatasetButton.Position = [16 70 160 36];
            app.SelectDatasetButton.Text = 'Izaberi dataset';

            % Create DatasetPathLabel
            app.DatasetPathLabel = uilabel(app.DatasetPanel);
            app.DatasetPathLabel.FontName = 'Courier New';
            app.DatasetPathLabel.FontSize = 11;
            app.DatasetPathLabel.WordWrap = 'on';
            app.DatasetPathLabel.VerticalAlignment = 'top';
            app.DatasetPathLabel.Position = [16 38 340 28];
            app.DatasetPathLabel.Text = '';

            % Create DatasetInfoLabel
            app.DatasetInfoLabel = uilabel(app.DatasetPanel);
            app.DatasetInfoLabel.FontSize = 12;
            app.DatasetInfoLabel.Position = [16 8 340 24];
            app.DatasetInfoLabel.Text = '';

            %% Parametri

            % Create ParamsPanel
            app.ParamsPanel = uipanel(app.UIFigure);
            app.ParamsPanel.Title = 'Parametri';
            app.ParamsPanel.FontSize = 14;
            app.ParamsPanel.FontWeight = 'bold';
            app.ParamsPanel.Position = [24 24 372 504];

            % Create CommonSectionLabel
            app.CommonSectionLabel = uilabel(app.ParamsPanel);
            app.CommonSectionLabel.FontSize = 13;
            app.CommonSectionLabel.FontWeight = 'bold';
            app.CommonSectionLabel.Position = [16 450 340 22];
            app.CommonSectionLabel.Text = 'Zajednički parametri';

            % Create LatentDimLabel
            app.LatentDimLabel = uilabel(app.ParamsPanel);
            app.LatentDimLabel.FontSize = 12;
            app.LatentDimLabel.Position = [16 414 176 24];
            app.LatentDimLabel.Text = 'Latentna dimenzija';

            % Create LatentDimSpinner
            app.LatentDimSpinner = uispinner(app.ParamsPanel);
            app.LatentDimSpinner.Limits = [1 512];
            app.LatentDimSpinner.RoundFractionalValues = 'on';
            app.LatentDimSpinner.FontSize = 12;
            app.LatentDimSpinner.Position = [200 414 140 24];
            app.LatentDimSpinner.Value = 16;

            % Create EpochsLabel
            app.EpochsLabel = uilabel(app.ParamsPanel);
            app.EpochsLabel.FontSize = 12;
            app.EpochsLabel.Position = [16 378 176 24];
            app.EpochsLabel.Text = 'Broj epoha';

            % Create EpochsSpinner
            app.EpochsSpinner = uispinner(app.ParamsPanel);
            app.EpochsSpinner.Limits = [1 500];
            app.EpochsSpinner.RoundFractionalValues = 'on';
            app.EpochsSpinner.FontSize = 12;
            app.EpochsSpinner.Position = [200 378 140 24];
            app.EpochsSpinner.Value = 20;

            % Create BatchSizeLabel
            app.BatchSizeLabel = uilabel(app.ParamsPanel);
            app.BatchSizeLabel.FontSize = 12;
            app.BatchSizeLabel.Position = [16 342 176 24];
            app.BatchSizeLabel.Text = 'Veličina batch-a';

            % Create BatchSizeEditField
            app.BatchSizeEditField = uieditfield(app.ParamsPanel, 'numeric');
            app.BatchSizeEditField.Limits = [1 4096];
            app.BatchSizeEditField.RoundFractionalValues = 'on';
            app.BatchSizeEditField.ValueDisplayFormat = '%d';
            app.BatchSizeEditField.FontSize = 12;
            app.BatchSizeEditField.Position = [200 342 140 24];
            app.BatchSizeEditField.Value = 128;

            % Create LearnRateLabel
            app.LearnRateLabel = uilabel(app.ParamsPanel);
            app.LearnRateLabel.FontSize = 12;
            app.LearnRateLabel.Position = [16 306 176 24];
            app.LearnRateLabel.Text = 'Learning rate';

            % Create LearnRateEditField
            app.LearnRateEditField = uieditfield(app.ParamsPanel, 'numeric');
            app.LearnRateEditField.Limits = [0 1];
            app.LearnRateEditField.LowerLimitInclusive = 'off';
            app.LearnRateEditField.ValueDisplayFormat = '%.4g';
            app.LearnRateEditField.FontSize = 12;
            app.LearnRateEditField.Position = [200 306 140 24];
            app.LearnRateEditField.Value = 0.001;

            % Create SeedLabel
            app.SeedLabel = uilabel(app.ParamsPanel);
            app.SeedLabel.FontSize = 12;
            app.SeedLabel.Position = [16 270 176 24];
            app.SeedLabel.Text = 'Seed';

            % Create SeedEditField
            app.SeedEditField = uieditfield(app.ParamsPanel, 'numeric');
            app.SeedEditField.Limits = [0 1000000000];
            app.SeedEditField.RoundFractionalValues = 'on';
            app.SeedEditField.ValueDisplayFormat = '%d';
            app.SeedEditField.FontSize = 12;
            app.SeedEditField.Position = [200 270 140 24];
            app.SeedEditField.Value = 1;

            % Create MaxImagesLabel
            app.MaxImagesLabel = uilabel(app.ParamsPanel);
            app.MaxImagesLabel.FontSize = 12;
            app.MaxImagesLabel.Position = [16 234 176 24];
            app.MaxImagesLabel.Text = 'Broj slika (0 = sve)';

            % Create MaxImagesEditField
            app.MaxImagesEditField = uieditfield(app.ParamsPanel, 'numeric');
            app.MaxImagesEditField.Limits = [0 1000000];
            app.MaxImagesEditField.RoundFractionalValues = 'on';
            app.MaxImagesEditField.ValueDisplayFormat = '%d';
            app.MaxImagesEditField.FontSize = 12;
            app.MaxImagesEditField.Position = [200 234 140 24];
            app.MaxImagesEditField.Value = 10000;

            % Create VaeSectionLabel
            app.VaeSectionLabel = uilabel(app.ParamsPanel);
            app.VaeSectionLabel.FontSize = 13;
            app.VaeSectionLabel.FontWeight = 'bold';
            app.VaeSectionLabel.Position = [16 196 340 22];
            app.VaeSectionLabel.Text = 'VAE parametri';

            % Create BetaLabel
            app.BetaLabel = uilabel(app.ParamsPanel);
            app.BetaLabel.FontSize = 12;
            app.BetaLabel.Position = [16 160 176 24];
            app.BetaLabel.Text = 'β (težina KL člana)';

            % Create BetaEditField
            app.BetaEditField = uieditfield(app.ParamsPanel, 'numeric');
            app.BetaEditField.Limits = [0 1000];
            app.BetaEditField.ValueDisplayFormat = '%.4g';
            app.BetaEditField.FontSize = 12;
            app.BetaEditField.Position = [200 160 140 24];
            app.BetaEditField.Value = 1;

            % Create ReconLossLabel
            app.ReconLossLabel = uilabel(app.ParamsPanel);
            app.ReconLossLabel.FontSize = 12;
            app.ReconLossLabel.Position = [16 124 176 24];
            app.ReconLossLabel.Text = 'Rekonstrukcijski gubitak';

            % Create ReconLossDropDown
            app.ReconLossDropDown = uidropdown(app.ParamsPanel);
            app.ReconLossDropDown.Items = {'BCE', 'MSE'};
            app.ReconLossDropDown.FontSize = 12;
            app.ReconLossDropDown.Position = [200 124 140 24];
            app.ReconLossDropDown.Value = 'BCE';

            % Create StopButton
            app.StopButton = uibutton(app.ParamsPanel, 'push');
            app.StopButton.ButtonPushedFcn = createCallbackFcn(app, @StopButtonPushed, true);
            app.StopButton.FontSize = 12;
            app.StopButton.Enable = 'off';
            app.StopButton.Position = [16 72 160 36];
            app.StopButton.Text = 'Zaustavi';

            % Create StartTrainingButton
            app.StartTrainingButton = uibutton(app.ParamsPanel, 'push');
            app.StartTrainingButton.ButtonPushedFcn = createCallbackFcn(app, @StartTrainingButtonPushed, true);
            app.StartTrainingButton.BackgroundColor = [0.20 0.45 0.75];
            app.StartTrainingButton.FontColor = [1 1 1];
            app.StartTrainingButton.FontSize = 13;
            app.StartTrainingButton.FontWeight = 'bold';
            app.StartTrainingButton.Position = [16 16 200 44];
            app.StartTrainingButton.Text = 'Započni treniranje';

            %% Gubici

            % Create LossPanel
            app.LossPanel = uipanel(app.UIFigure);
            app.LossPanel.Title = 'Gubici';
            app.LossPanel.FontSize = 14;
            app.LossPanel.FontWeight = 'bold';
            app.LossPanel.Position = [412 356 764 328];

            % Create TotalLossAxes
            app.TotalLossAxes = uiaxes(app.LossPanel);
            app.TotalLossAxes.Position = [12 12 240 280];

            % Create ReconLossAxes
            app.ReconLossAxes = uiaxes(app.LossPanel);
            app.ReconLossAxes.Position = [262 12 240 280];

            % Create KLLossAxes
            app.KLLossAxes = uiaxes(app.LossPanel);
            app.KLLossAxes.Position = [512 12 240 280];

            %% Generisani uzorci

            % Create SamplesPanel
            app.SamplesPanel = uipanel(app.UIFigure);
            app.SamplesPanel.Title = 'Generisani uzorci (fiksni latentni vektor)';
            app.SamplesPanel.FontSize = 14;
            app.SamplesPanel.FontWeight = 'bold';
            app.SamplesPanel.Position = [412 24 764 316];

            % Create SamplesAxes
            app.SamplesAxes = uiaxes(app.SamplesPanel);
            app.SamplesAxes.XTick = [];
            app.SamplesAxes.YTick = [];
            app.SamplesAxes.Position = [232 12 300 262];

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = ImageGeneratingModelTraining

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
