classdef cnn_Menu < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                      matlab.ui.Figure
        GenerisanjeslikaButton        matlab.ui.control.Button
        TreniranjegenerativnogmodelaButton  matlab.ui.control.Button
        UvoduCNNButton                matlab.ui.control.Button
        EvaluacijametrikaButton       matlab.ui.control.Button
        KlasifikacijaslikaButton      matlab.ui.control.Button
        TreniranjeCNNmodelaPanel      matlab.ui.container.Panel
        TreniranjeCNNButton           matlab.ui.control.Button
        OdabirdatasetaButton          matlab.ui.control.Button
        IzaberiarhitekturuButton      matlab.ui.control.Button
        NormLabelInput                matlab.ui.control.Label
        NormalizacijaLabel            matlab.ui.control.Label
        DataSetLabelInput             matlab.ui.control.Label
        DatasetLabel                  matlab.ui.control.Label
        ArchLabel                     matlab.ui.control.Label
        ArhitekturaLabel              matlab.ui.control.Label
        DobrodoliuCNNanalizuslikaPhotoLabaLabel  matlab.ui.control.Label
        DescriptionLabel              matlab.ui.control.Label
        AnalysisPanel                 matlab.ui.container.Panel
        GenerativePanel               matlab.ui.container.Panel
    end

    
    properties (Access = public)
        Architecture % Description
        Dataset % here will be path to choosen dataset
        DatasetName
        DatasetDimensions
        DatasetNormalization % 'None' | 'MinMax' | 'Mean-Std', applied in the network input layer
    end
    
  
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            movegui(app.UIFigure, 'center');
            % Helper folders next to this app, so it also works when opened directly
            appDir = fileparts(which('cnn_Menu'));
            folders = {'cnn_ui', 'options_ui', 'scripts', 'metrics', 'utils', 'generative'};
            for k = 1:numel(folders)
                folder = fullfile(appDir, folders{k});
                if isfolder(folder)
                    addpath(folder);
                end
            end
        end

        % Button pushed function: IzaberiarhitekturuButton
        function IzaberiarhitekturuButtonPushed(app, event)
            architectures = CNNArchitectures();
            architectures.ParentApp = app; % Pass the parent app reference
    
            % Wait for the user to select an architecture
            uiwait(architectures.CNNArchitecturesUIFigure);
            
            % Access the chosen architecture from the child app
            if isvalid(architectures) && ~isempty(architectures.choosenArch)
                app.Architecture = architectures.choosenArch; % Update parent app
                app.ArchLabel.Text = architectures.choosenArch;
            end

            delete(architectures);
        end

        % Button pushed function: OdabirdatasetaButton
        function OdabirdatasetaButtonPushed(app, event)
            % Instantiate the DatasetSelection app
            datasetApp = DatasetManagerApp();
            datasetApp.ParentApp = app; % Pass parent app reference
        
            % Wait for user input
            uiwait(datasetApp.UIFigure);
            % Retrieve the selected dataset
            if isvalid(datasetApp) && ~isempty(datasetApp.choosenDataset) && ~isempty(datasetApp.setDimensions)
                app.Dataset = datasetApp.choosenDataset;
                app.DatasetDimensions = datasetApp.setDimensions;
                app.DatasetNormalization = datasetApp.setNormalization;
                disp(datasetApp.choosenDataset);
                [~, fileName, ~] = fileparts(app.Dataset);
                app.DatasetName = fileName;
                app.DataSetLabelInput.Text = app.DatasetName;
                app.NormLabelInput.Text = app.DatasetNormalization;
            end
        
            delete(datasetApp); % Close the child app
        end

        % Button pushed function: TreniranjeCNNButton
        function TreniranjeCNNButtonPushed(app, event)
            if ~isempty(app.Architecture) && ~isempty(app.Dataset)
                trainingApp = TrainingCNN();
                trainingApp.loadData(app.Architecture, app.Dataset, app.DatasetDimensions, app.DatasetNormalization);
            else
                uialert(app.UIFigure, 'Arhitektura ili dataset nisu izabrani!', 'Warning');
            end
        end

        % Button pushed function: KlasifikacijaslikaButton
        function KlasifikacijaslikaButtonPushed(app, event)
             % Otvori ImageClassificationApp
    try
        % Napravi instancu aplikacije
        imgClassApp = ImageClassificationApp();
        
        % Opcionalno: prosledi dataset iz parent aplikacije
        imgClassApp.UIFigure.UserData.Dataset = app.Dataset;
        imgClassApp.UIFigure.UserData.DatasetDimensions = app.DatasetDimensions;
    catch ME
        % Ako dođe do greške prikaži alert
        uialert(app.UIFigure, sprintf('Ne mogu da otvorim ImageClassificationApp:\n%s', ME.message), 'Greška');
    end
        end

        % Button pushed function: EvaluacijametrikaButton
        function EvaluacijametrikaButtonPushed(app, event)
             try
        % Napravi instancu EvaluationMetricsApp
        evalApp = EvaluationMetricsApp();

        % Opcionalno: prosledi neke podatke iz parent app, ako želiš
        if isfield(app.UIFigure.UserData,'net')
            evalApp.UIFigure.UserData.net = app.UIFigure.UserData.net;
        end
        if isfield(app.UIFigure.UserData,'yTrue')
            evalApp.UIFigure.UserData.yTrue = app.UIFigure.UserData.yTrue;
        end
        if isfield(app.UIFigure.UserData,'yPred')
            evalApp.UIFigure.UserData.yPred = app.UIFigure.UserData.yPred;
        end

    catch ME
        % Ako dođe do greške prikaži alert
        uialert(app.UIFigure, sprintf('Ne mogu da otvorim EvaluationMetricsApp:\n%s', ME.message), 'Greška');
             end
        end

        % Button pushed function: UvoduCNNButton
        function UvoduCNNButtonPushed(app, event)
            CNNIntroductionApp();
        end

        % Button pushed function: TreniranjegenerativnogmodelaButton
        function TreniranjegenerativnogmodelaButtonPushed(app, event)
            try
                ImageGeneratingModelTraining();
            catch ME
                uialert(app.UIFigure, sprintf('Ne mogu da otvorim ImageGeneratingModelTraining:\n%s', ME.message), 'Greška');
            end
        end

        % Button pushed function: GenerisanjeslikaButton
        function GenerisanjeslikaButtonPushed(app, event)
            try
                ImageGeneratingFromModel();
            catch ME
                uialert(app.UIFigure, sprintf('Ne mogu da otvorim ImageGeneratingFromModel:\n%s', ME.message), 'Greška');
            end
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 1200 760];
            app.UIFigure.Name = 'CNN analiza slika';

            % Create DobrodoliuCNNanalizuslikaPhotoLabaLabel
            app.DobrodoliuCNNanalizuslikaPhotoLabaLabel = uilabel(app.UIFigure);
            app.DobrodoliuCNNanalizuslikaPhotoLabaLabel.FontSize = 22;
            app.DobrodoliuCNNanalizuslikaPhotoLabaLabel.FontWeight = 'bold';
            app.DobrodoliuCNNanalizuslikaPhotoLabaLabel.Position = [24 704 800 32];
            app.DobrodoliuCNNanalizuslikaPhotoLabaLabel.Text = 'Dobro došli u CNN analizu slika PhotoLab-a';

            % Create DescriptionLabel
            app.DescriptionLabel = uilabel(app.UIFigure);
            app.DescriptionLabel.FontSize = 13;
            app.DescriptionLabel.WordWrap = 'on';
            app.DescriptionLabel.Position = [24 668 1152 24];
            app.DescriptionLabel.Text = 'Izaberite arhitekturu i dataset pa pokrenite treniranje CNN modela, ili otvorite ostale alate.';

            %% Treniranje CNN modela

            % Create TreniranjeCNNmodelaPanel
            app.TreniranjeCNNmodelaPanel = uipanel(app.UIFigure);
            app.TreniranjeCNNmodelaPanel.Title = 'Treniranje CNN modela';
            app.TreniranjeCNNmodelaPanel.FontSize = 14;
            app.TreniranjeCNNmodelaPanel.FontWeight = 'bold';
            app.TreniranjeCNNmodelaPanel.Position = [24 408 1152 244];

            % Create ArhitekturaLabel
            app.ArhitekturaLabel = uilabel(app.TreniranjeCNNmodelaPanel);
            app.ArhitekturaLabel.FontSize = 13;
            app.ArhitekturaLabel.Position = [16 150 120 24];
            app.ArhitekturaLabel.Text = 'Arhitektura:';

            % Create ArchLabel
            app.ArchLabel = uilabel(app.TreniranjeCNNmodelaPanel);
            app.ArchLabel.FontSize = 13;
            app.ArchLabel.Position = [140 150 480 24];
            app.ArchLabel.Text = '';

            % Create DatasetLabel
            app.DatasetLabel = uilabel(app.TreniranjeCNNmodelaPanel);
            app.DatasetLabel.FontSize = 13;
            app.DatasetLabel.Position = [16 114 120 24];
            app.DatasetLabel.Text = 'Dataset:';

            % Create DataSetLabelInput
            app.DataSetLabelInput = uilabel(app.TreniranjeCNNmodelaPanel);
            app.DataSetLabelInput.FontSize = 13;
            app.DataSetLabelInput.Position = [140 114 480 24];
            app.DataSetLabelInput.Text = '';

            % Create NormalizacijaLabel
            app.NormalizacijaLabel = uilabel(app.TreniranjeCNNmodelaPanel);
            app.NormalizacijaLabel.FontSize = 13;
            app.NormalizacijaLabel.Position = [16 78 120 24];
            app.NormalizacijaLabel.Text = 'Normalizacija:';

            % Create NormLabelInput
            app.NormLabelInput = uilabel(app.TreniranjeCNNmodelaPanel);
            app.NormLabelInput.FontSize = 13;
            app.NormLabelInput.Position = [140 78 480 24];
            app.NormLabelInput.Text = '';

            % Create IzaberiarhitekturuButton
            app.IzaberiarhitekturuButton = uibutton(app.TreniranjeCNNmodelaPanel, 'push');
            app.IzaberiarhitekturuButton.ButtonPushedFcn = createCallbackFcn(app, @IzaberiarhitekturuButtonPushed, true);
            app.IzaberiarhitekturuButton.FontSize = 12;
            app.IzaberiarhitekturuButton.WordWrap = 'on';
            app.IzaberiarhitekturuButton.Position = [640 150 240 48];
            app.IzaberiarhitekturuButton.Text = 'Izaberi arhitekturu';

            % Create OdabirdatasetaButton
            app.OdabirdatasetaButton = uibutton(app.TreniranjeCNNmodelaPanel, 'push');
            app.OdabirdatasetaButton.ButtonPushedFcn = createCallbackFcn(app, @OdabirdatasetaButtonPushed, true);
            app.OdabirdatasetaButton.FontSize = 12;
            app.OdabirdatasetaButton.WordWrap = 'on';
            app.OdabirdatasetaButton.Position = [896 150 240 48];
            app.OdabirdatasetaButton.Text = 'Odabir dataset-a';

            % Create TreniranjeCNNButton
            app.TreniranjeCNNButton = uibutton(app.TreniranjeCNNmodelaPanel, 'push');
            app.TreniranjeCNNButton.ButtonPushedFcn = createCallbackFcn(app, @TreniranjeCNNButtonPushed, true);
            app.TreniranjeCNNButton.BackgroundColor = [0.20 0.45 0.75];
            app.TreniranjeCNNButton.FontColor = [1 1 1];
            app.TreniranjeCNNButton.FontSize = 13;
            app.TreniranjeCNNButton.FontWeight = 'bold';
            app.TreniranjeCNNButton.Position = [936 60 200 44];
            app.TreniranjeCNNButton.Text = 'Treniranje CNN';

            %% Klasifikacija i evaluacija

            % Create AnalysisPanel
            app.AnalysisPanel = uipanel(app.UIFigure);
            app.AnalysisPanel.Title = 'Klasifikacija i evaluacija';
            app.AnalysisPanel.FontSize = 14;
            app.AnalysisPanel.FontWeight = 'bold';
            app.AnalysisPanel.Position = [24 268 1152 124];

            % Create KlasifikacijaslikaButton
            app.KlasifikacijaslikaButton = uibutton(app.AnalysisPanel, 'push');
            app.KlasifikacijaslikaButton.ButtonPushedFcn = createCallbackFcn(app, @KlasifikacijaslikaButtonPushed, true);
            app.KlasifikacijaslikaButton.FontSize = 12;
            app.KlasifikacijaslikaButton.WordWrap = 'on';
            app.KlasifikacijaslikaButton.Position = [16 24 240 48];
            app.KlasifikacijaslikaButton.Text = 'Klasifikacija slika';

            % Create EvaluacijametrikaButton
            app.EvaluacijametrikaButton = uibutton(app.AnalysisPanel, 'push');
            app.EvaluacijametrikaButton.ButtonPushedFcn = createCallbackFcn(app, @EvaluacijametrikaButtonPushed, true);
            app.EvaluacijametrikaButton.FontSize = 12;
            app.EvaluacijametrikaButton.WordWrap = 'on';
            app.EvaluacijametrikaButton.Position = [272 24 240 48];
            app.EvaluacijametrikaButton.Text = 'Evaluacija metrika';

            %% Generativni modeli

            % Create GenerativePanel
            app.GenerativePanel = uipanel(app.UIFigure);
            app.GenerativePanel.Title = 'Generativni modeli';
            app.GenerativePanel.FontSize = 14;
            app.GenerativePanel.FontWeight = 'bold';
            app.GenerativePanel.Position = [24 128 1152 124];

            % Create TreniranjegenerativnogmodelaButton
            app.TreniranjegenerativnogmodelaButton = uibutton(app.GenerativePanel, 'push');
            app.TreniranjegenerativnogmodelaButton.ButtonPushedFcn = createCallbackFcn(app, @TreniranjegenerativnogmodelaButtonPushed, true);
            app.TreniranjegenerativnogmodelaButton.FontSize = 12;
            app.TreniranjegenerativnogmodelaButton.WordWrap = 'on';
            app.TreniranjegenerativnogmodelaButton.Position = [16 24 240 48];
            app.TreniranjegenerativnogmodelaButton.Text = 'Treniranje generativnog modela';

            % Create GenerisanjeslikaButton
            app.GenerisanjeslikaButton = uibutton(app.GenerativePanel, 'push');
            app.GenerisanjeslikaButton.ButtonPushedFcn = createCallbackFcn(app, @GenerisanjeslikaButtonPushed, true);
            app.GenerisanjeslikaButton.FontSize = 12;
            app.GenerisanjeslikaButton.WordWrap = 'on';
            app.GenerisanjeslikaButton.Position = [272 24 240 48];
            app.GenerisanjeslikaButton.Text = 'Generisanje slika';

            %% Uvod

            % Create UvoduCNNButton
            app.UvoduCNNButton = uibutton(app.UIFigure, 'push');
            app.UvoduCNNButton.ButtonPushedFcn = createCallbackFcn(app, @UvoduCNNButtonPushed, true);
            app.UvoduCNNButton.FontSize = 12;
            app.UvoduCNNButton.WordWrap = 'on';
            app.UvoduCNNButton.Position = [936 40 240 48];
            app.UvoduCNNButton.Text = 'Uvod u CNN';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = cnn_Menu

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