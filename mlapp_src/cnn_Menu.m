classdef cnn_Menu < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                      matlab.ui.Figure
        SemantickasegmentacijaButton  matlab.ui.control.Button
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

        % Button pushed function: SemantickasegmentacijaButton
        function SemantickasegmentacijaButtonPushed(app, event)
        
         try
        % Napravi instancu SemanticSegmentationApp
        semanticApp = SemanticSegmentationApp();

        % Ako app ima UIFigure, učini ga vidljivim
        if isprop(semanticApp, 'UIFigure') && isvalid(semanticApp.UIFigure)
            semanticApp.UIFigure.Visible = 'on';
        end

        % Opcionalno: prosledi dataset ili druge podatke
        if ~isempty(app.Dataset)
            semanticApp.UIFigure.UserData.Dataset = app.Dataset;
            semanticApp.UIFigure.UserData.DatasetDimensions = app.DatasetDimensions;
        end
    catch ME
        uialert(app.UIFigure, sprintf('Ne mogu da otvorim SemanticSegmentationApp:\n%s', ME.message), 'Greška');
    end
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 1040 681];
            app.UIFigure.Name = 'MATLAB App';

            % Create DobrodoliuCNNanalizuslikaPhotoLabaLabel
            app.DobrodoliuCNNanalizuslikaPhotoLabaLabel = uilabel(app.UIFigure);
            app.DobrodoliuCNNanalizuslikaPhotoLabaLabel.FontSize = 24;
            app.DobrodoliuCNNanalizuslikaPhotoLabaLabel.Position = [26 621 482 32];
            app.DobrodoliuCNNanalizuslikaPhotoLabaLabel.Text = 'Dobro došli u CNN analizu slika PhotoLab-a';

            % Create ArhitekturaLabel
            app.ArhitekturaLabel = uilabel(app.UIFigure);
            app.ArhitekturaLabel.FontSize = 18;
            app.ArhitekturaLabel.Position = [26 577 97 23];
            app.ArhitekturaLabel.Text = 'Arhitektura:';

            % Create ArchLabel
            app.ArchLabel = uilabel(app.UIFigure);
            app.ArchLabel.FontSize = 18;
            app.ArchLabel.Position = [137 577 371 23];
            app.ArchLabel.Text = '';

            % Create DatasetLabel
            app.DatasetLabel = uilabel(app.UIFigure);
            app.DatasetLabel.FontSize = 18;
            app.DatasetLabel.Position = [26 541 72 23];
            app.DatasetLabel.Text = 'Dataset:';

            % Create DataSetLabelInput
            app.DataSetLabelInput = uilabel(app.UIFigure);
            app.DataSetLabelInput.FontSize = 18;
            app.DataSetLabelInput.Position = [137 541 371 23];
            app.DataSetLabelInput.Text = '';

            % Create NormalizacijaLabel
            app.NormalizacijaLabel = uilabel(app.UIFigure);
            app.NormalizacijaLabel.FontSize = 18;
            app.NormalizacijaLabel.Position = [26 505 120 23];
            app.NormalizacijaLabel.Text = 'Normalizacija:';

            % Create NormLabelInput
            app.NormLabelInput = uilabel(app.UIFigure);
            app.NormLabelInput.FontSize = 18;
            app.NormLabelInput.Position = [152 505 356 23];
            app.NormLabelInput.Text = '';

            % Create TreniranjeCNNmodelaPanel
            app.TreniranjeCNNmodelaPanel = uipanel(app.UIFigure);
            app.TreniranjeCNNmodelaPanel.Title = 'Treniranje CNN modela';
            app.TreniranjeCNNmodelaPanel.Position = [26 276 368 207];

            % Create IzaberiarhitekturuButton
            app.IzaberiarhitekturuButton = uibutton(app.TreniranjeCNNmodelaPanel, 'push');
            app.IzaberiarhitekturuButton.ButtonPushedFcn = createCallbackFcn(app, @IzaberiarhitekturuButtonPushed, true);
            app.IzaberiarhitekturuButton.FontSize = 14;
            app.IzaberiarhitekturuButton.Position = [11 114 160 42];
            app.IzaberiarhitekturuButton.Text = 'Izaberi arhitekturu';

            % Create OdabirdatasetaButton
            app.OdabirdatasetaButton = uibutton(app.TreniranjeCNNmodelaPanel, 'push');
            app.OdabirdatasetaButton.ButtonPushedFcn = createCallbackFcn(app, @OdabirdatasetaButtonPushed, true);
            app.OdabirdatasetaButton.FontSize = 14;
            app.OdabirdatasetaButton.Position = [189 114 160 42];
            app.OdabirdatasetaButton.Text = 'Odabir dataset-a';

            % Create TreniranjeCNNButton
            app.TreniranjeCNNButton = uibutton(app.TreniranjeCNNmodelaPanel, 'push');
            app.TreniranjeCNNButton.ButtonPushedFcn = createCallbackFcn(app, @TreniranjeCNNButtonPushed, true);
            app.TreniranjeCNNButton.Position = [11 36 160 42];
            app.TreniranjeCNNButton.Text = 'Treniranje CNN';

            % Create KlasifikacijaslikaButton
            app.KlasifikacijaslikaButton = uibutton(app.UIFigure, 'push');
            app.KlasifikacijaslikaButton.ButtonPushedFcn = createCallbackFcn(app, @KlasifikacijaslikaButtonPushed, true);
            app.KlasifikacijaslikaButton.Position = [26 223 159 41];
            app.KlasifikacijaslikaButton.Text = 'Klasifikacija slika';

            % Create EvaluacijametrikaButton
            app.EvaluacijametrikaButton = uibutton(app.UIFigure, 'push');
            app.EvaluacijametrikaButton.ButtonPushedFcn = createCallbackFcn(app, @EvaluacijametrikaButtonPushed, true);
            app.EvaluacijametrikaButton.Position = [26 159 159 39];
            app.EvaluacijametrikaButton.Text = 'Evaluacija metrika';

            % Create UvoduCNNButton
            app.UvoduCNNButton = uibutton(app.UIFigure, 'push');
            app.UvoduCNNButton.ButtonPushedFcn = createCallbackFcn(app, @UvoduCNNButtonPushed, true);
            app.UvoduCNNButton.Position = [852 38 159 41];
            app.UvoduCNNButton.Text = 'Uvod u CNN';

            % Create SemantickasegmentacijaButton
            app.SemantickasegmentacijaButton = uibutton(app.UIFigure, 'push');
            app.SemantickasegmentacijaButton.ButtonPushedFcn = createCallbackFcn(app, @SemantickasegmentacijaButtonPushed, true);
            app.SemantickasegmentacijaButton.Position = [26 108 157 33];
            app.SemantickasegmentacijaButton.Text = 'Semanticka segmentacija';

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