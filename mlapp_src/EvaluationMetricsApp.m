classdef EvaluationMetricsApp < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                  matlab.ui.Figure
        TitleLabel                matlab.ui.control.Label
        InputPanel                matlab.ui.container.Panel
        LoadModelButton           matlab.ui.control.Button
        ModelNameLabel            matlab.ui.control.Label
        ModelInfoLabel            matlab.ui.control.Label
        LoadDatasetButton         matlab.ui.control.Button
        DatasetPathLabel          matlab.ui.control.Label
        ImportPredictionsButton   matlab.ui.control.Button
        PredSourceLabel           matlab.ui.control.Label
        ExportPredictionsButton   matlab.ui.control.Button
        HintLabel                 matlab.ui.control.Label
        ComputeMetricsButton      matlab.ui.control.Button
        MetricsPanel              matlab.ui.container.Panel
        AccuracyCaptionLabel      matlab.ui.control.Label
        AccuracyValueLabel        matlab.ui.control.Label
        PrecisionCaptionLabel     matlab.ui.control.Label
        PrecisionValueLabel       matlab.ui.control.Label
        RecallCaptionLabel        matlab.ui.control.Label
        RecallValueLabel          matlab.ui.control.Label
        F1CaptionLabel            matlab.ui.control.Label
        F1ValueLabel              matlab.ui.control.Label
        ConfusionPanel            matlab.ui.container.Panel
        ConfusionMatrixAxes       matlab.ui.control.UIAxes
        PerClassPanel             matlab.ui.container.Panel
        BarChartAxes              matlab.ui.control.UIAxes
        ConfusionsPanel           matlab.ui.container.Panel
        ConfusionsTable           matlab.ui.control.Table
    end

    methods (Access = private)

        function names = displayName(~, classNames)
            % '02_Trouser' -> 'Trouser'; plain digit folders ('7') stay as they are
            names = regexprep(string(classNames), '^\d+_', '');
        end

        function model = findNetwork(~, loadedData)
            % 'net' first, otherwise the first SeriesNetwork/DAGNetwork variable
            model = [];
            if isfield(loadedData, 'net') && (isa(loadedData.net, 'SeriesNetwork') || isa(loadedData.net, 'DAGNetwork'))
                model = loadedData.net;
                return;
            end
            fn = fieldnames(loadedData);
            for k = 1:numel(fn)
                candidate = loadedData.(fn{k});
                if isa(candidate, 'SeriesNetwork') || isa(candidate, 'DAGNetwork')
                    model = candidate;
                    return;
                end
            end
        end

        function [yTrue, yPred] = toCategoricalPair(~, yTrue, yPred)
            % Bring labels from a model, .mat or .csv into two categoricals with one category set
            if numel(yTrue) ~= numel(yPred) || isempty(yTrue)
                error('yTrue i yPred moraju imati isti broj elemenata (veći od nule).');
            end
            yT = string(yTrue(:));
            yP = string(yPred(:));
            if iscategorical(yTrue)
                cats = string(categories(yTrue));
            elseif isnumeric(yTrue) && isnumeric(yPred)
                cats = string(unique([yTrue(:); yPred(:)]));
            else
                cats = unique([yT; yP], 'stable');
            end
            extra = setdiff(unique(yP), cats, 'stable');
            cats = [cats(:); extra(:)];
            if any(ismissing(yT)) || any(ismissing(yP))
                error('yTrue i yPred sadrže nedostajuće vrijednosti.');
            end
            yTrue = categorical(yT, cats);
            yPred = categorical(yP, cats);
        end

        function setPredictions(app, yTrue, yPred, testFiles, sourceText)
            % Remember the labels used by Izračunaj metrike / Izvezi CSV
            [yTrue, yPred] = toCategoricalPair(app, yTrue, yPred);
            app.UIFigure.UserData.YTrue = yTrue;
            app.UIFigure.UserData.YPred = yPred;
            app.UIFigure.UserData.TestFiles = testFiles;
            app.PredSourceLabel.Text = sprintf('%s (%d uzoraka)', sourceText, numel(yTrue));
        end

        function clearOutputs(app)
            cla(app.ConfusionMatrixAxes);
            cla(app.BarChartAxes);
            app.ConfusionsTable.Data = table();
            app.AccuracyValueLabel.Text = '—';
            app.PrecisionValueLabel.Text = '—';
            app.RecallValueLabel.Text = '—';
            app.F1ValueLabel.Text = '—';
        end

        function showMetrics(app)
            yTrue = app.UIFigure.UserData.YTrue;
            yPred = app.UIFigure.UserData.YPred;

            classes = unique(yTrue);
            n = numel(classes);
            names = displayName(app, classes);

            acc = computeAccuracy(yTrue, yPred);
            prec = computePrecision(yTrue, yPred);
            rec = computeRecall(yTrue, yPred);
            f1 = computeF1(yTrue, yPred);

            app.AccuracyValueLabel.Text = sprintf('%.2f%%', acc * 100);
            app.PrecisionValueLabel.Text = sprintf('%.2f%%', mean(prec) * 100);
            app.RecallValueLabel.Text = sprintf('%.2f%%', mean(rec) * 100);
            app.F1ValueLabel.Text = sprintf('%.2f%%', mean(f1) * 100);

            % Confusion matrix
            cm = confusionmat(yTrue, yPred, 'Order', classes);
            ax = app.ConfusionMatrixAxes;
            cla(ax);
            imagesc(ax, cm);
            colormap(ax, parula);
            colorbar(ax);
            xlabel(ax, 'Predviđena klasa');
            ylabel(ax, 'Stvarna klasa');
            axis(ax, 'tight');
            if n <= 20
                xticks(ax, 1:n);
                yticks(ax, 1:n);
                xticklabels(ax, names);
                yticklabels(ax, names);
            else
                xticks(ax, []);
                yticks(ax, []);
            end
            if n <= 12
                [X, Y] = meshgrid(1:n);
                high = cm(:) > max(cm(:)) / 2;
                if any(high)
                    text(ax, X(high), Y(high), cellstr(string(cm(high))), ...
                        'HorizontalAlignment', 'center', 'FontSize', 9, 'Color', 'k');
                end
                if any(~high)
                    text(ax, X(~high), Y(~high), cellstr(string(cm(~high))), ...
                        'HorizontalAlignment', 'center', 'FontSize', 9, 'Color', 'w');
                end
            end

            % Per-class Precision / Recall / F1
            ax = app.BarChartAxes;
            cla(ax);
            bar(ax, [prec; rec; f1]');
            if n <= 20
                xticks(ax, 1:n);
                xticklabels(ax, names);
            else
                xticks(ax, []);
            end
            ylim(ax, [0 1.05]);
            legend(ax, {'Precision', 'Recall', 'F1'}, 'Location', 'southoutside', 'Orientation', 'horizontal');
            ylabel(ax, 'Vrijednost');

            % Most frequent confusions
            T = topConfusions(yTrue, yPred, 10);
            T.Stvarna = displayName(app, T.Stvarna);
            T.("Predviđena") = displayName(app, T.("Predviđena"));
            app.ConfusionsTable.Data = T;
        end
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            movegui(app.UIFigure, 'center');
            app.UIFigure.UserData = struct('Net', [], 'YTrue', [], 'YPred', [], ...
                'TestFiles', [], 'DatasetPath', '');
        end

        % Button pushed function: LoadModelButton
        function LoadModelButtonPushed(app, event)
            [file, path] = uigetfile('*.mat', 'Izaberi istrenirani model');
            if isequal(file, 0)
                figure(app.UIFigure);
                return;
            end
            loadedData = load(fullfile(path, file));

            model = findNetwork(app, loadedData);
            if isempty(model)
                uialert(app.UIFigure, 'Fajl ne sadrži CNN mrežu (SeriesNetwork ili DAGNetwork)!', 'Greška');
                return;
            end

            app.UIFigure.UserData.Net = model;
            app.UIFigure.UserData.YTrue = [];
            app.UIFigure.UserData.YPred = [];
            app.UIFigure.UserData.TestFiles = [];
            app.ModelNameLabel.Text = file;
            clearOutputs(app);

            info = sprintf('Ulaz: %s  |  Klasa: %d', strjoin(string(model.Layers(1).InputSize), 'x'), ...
                numel(model.Layers(end).Classes));
            if isfield(loadedData, 'architecture')
                info = sprintf('Arhitektura: %s\n%s', loadedData.architecture, info);
            end
            if isfield(loadedData, 'datasetName')
                info = sprintf('%s\nDataset: %s', info, loadedData.datasetName);
            end
            if isfield(loadedData, 'accuracy')
                info = sprintf('%s\nTest tačnost: %.2f%%', info, 100 * loadedData.accuracy);
            end
            app.ModelInfoLabel.Text = info;

            if isfield(loadedData, 'yTrue') && isfield(loadedData, 'yPred')
                try
                    testFiles = [];
                    if isfield(loadedData, 'testFiles')
                        testFiles = loadedData.testFiles;
                    end
                    setPredictions(app, loadedData.yTrue, loadedData.yPred, testFiles, 'Predikcije iz modela');
                catch ME
                    app.PredSourceLabel.Text = '';
                    uialert(app.UIFigure, ME.message, 'Greška');
                end
            else
                app.PredSourceLabel.Text = 'Model nema sačuvane predikcije. Izaberite dataset.';
            end
        end

        % Button pushed function: LoadDatasetButton
        function LoadDatasetButtonPushed(app, event)
            folder = uigetdir('', 'Izaberi dataset folder');
            if isequal(folder, 0)
                figure(app.UIFigure);
                return;
            end
            if ~isfile(fullfile(folder, 'photolab_dataset.mat'))
                uialert(app.UIFigure, ...
                    'Folder ne sadrži photolab_dataset.mat. Izaberite dataset pripremljen u PhotoLab-u.', 'Greška');
                return;
            end
            app.UIFigure.UserData.DatasetPath = folder;
            app.DatasetPathLabel.Text = folder;
        end

        % Button pushed function: ImportPredictionsButton
        function ImportPredictionsButtonPushed(app, event)
            [file, path] = uigetfile({'*.mat;*.csv', 'Predikcije (*.mat, *.csv)'}, 'Uvezi yTrue i yPred');
            if isequal(file, 0)
                figure(app.UIFigure);
                return;
            end
            fullpath = fullfile(path, file);
            try
                [~, ~, ext] = fileparts(file);
                if strcmpi(ext, '.mat')
                    data = load(fullpath);
                    if ~(isfield(data, 'yTrue') && isfield(data, 'yPred'))
                        uialert(app.UIFigure, 'Fajl mora sadržavati promjenljive yTrue i yPred.', 'Greška');
                        return;
                    end
                    yTrue = data.yTrue;
                    yPred = data.yPred;
                else
                    tbl = readtable(fullpath);
                    if ~all(ismember({'yTrue', 'yPred'}, tbl.Properties.VariableNames))
                        uialert(app.UIFigure, 'CSV fajl mora imati kolone yTrue i yPred.', 'Greška');
                        return;
                    end
                    yTrue = tbl.yTrue;
                    yPred = tbl.yPred;
                end
                setPredictions(app, yTrue, yPred, [], ['Uvezeno iz ' file]);
            catch ME
                uialert(app.UIFigure, ME.message, 'Greška');
                return;
            end
            clearOutputs(app);
        end

        % Button pushed function: ExportPredictionsButton
        function ExportPredictionsButtonPushed(app, event)
            if isempty(app.UIFigure.UserData.YTrue)
                uialert(app.UIFigure, 'Morate izračunati ili učitati predikcije prvo!', 'Warning');
                return;
            end
            [file, path] = uiputfile('predikcije.csv', 'Izvezi yTrue i yPred');
            if isequal(file, 0)
                figure(app.UIFigure);
                return;
            end
            T = table(string(app.UIFigure.UserData.YTrue), string(app.UIFigure.UserData.YPred), ...
                'VariableNames', {'yTrue', 'yPred'});
            try
                writetable(T, fullfile(path, file));
            catch ME
                uialert(app.UIFigure, ME.message, 'Greška');
            end
        end

        % Button pushed function: ComputeMetricsButton
        function ComputeMetricsButtonPushed(app, event)
            data = app.UIFigure.UserData;

            if isempty(data.YTrue)
                if isempty(data.Net)
                    uialert(app.UIFigure, 'Morate učitati model prvo!', 'Warning');
                    return;
                end
                if isempty(data.DatasetPath)
                    uialert(app.UIFigure, 'Model nema sačuvane predikcije. Morate izabrati dataset prvo!', 'Warning');
                    return;
                end
                app.ComputeMetricsButton.Enable = 'off';
                dlg = uiprogressdlg(app.UIFigure, 'Title', 'Evaluacija', ...
                    'Message', 'Klasifikacija test skupa...', 'Indeterminate', 'on');
                try
                    [yTrue, yPred, files] = evaluateModelOnTestSet(data.Net, data.DatasetPath);
                    setPredictions(app, yTrue, yPred, files, 'Izračunato na test skupu dataseta');
                catch ME
                    close(dlg);
                    app.ComputeMetricsButton.Enable = 'on';
                    uialert(app.UIFigure, ME.message, 'Greška');
                    return;
                end
                close(dlg);
                app.ComputeMetricsButton.Enable = 'on';
            end

            showMetrics(app);
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 1200 760];
            app.UIFigure.Name = 'Evaluacija metrika';

            % Create TitleLabel
            app.TitleLabel = uilabel(app.UIFigure);
            app.TitleLabel.FontSize = 22;
            app.TitleLabel.FontWeight = 'bold';
            app.TitleLabel.Position = [24 704 800 32];
            app.TitleLabel.Text = 'Evaluacija metrika';

            %% Model i podaci

            % Create InputPanel
            app.InputPanel = uipanel(app.UIFigure);
            app.InputPanel.Title = 'Model i podaci';
            app.InputPanel.FontSize = 14;
            app.InputPanel.FontWeight = 'bold';
            app.InputPanel.Position = [24 24 372 660];

            % Create LoadModelButton
            app.LoadModelButton = uibutton(app.InputPanel, 'push');
            app.LoadModelButton.ButtonPushedFcn = createCallbackFcn(app, @LoadModelButtonPushed, true);
            app.LoadModelButton.FontSize = 12;
            app.LoadModelButton.Position = [16 590 160 36];
            app.LoadModelButton.Text = 'Učitaj model';

            % Create ModelNameLabel
            app.ModelNameLabel = uilabel(app.InputPanel);
            app.ModelNameLabel.FontName = 'Courier New';
            app.ModelNameLabel.FontSize = 11;
            app.ModelNameLabel.Position = [16 554 340 24];
            app.ModelNameLabel.Text = '';

            % Create ModelInfoLabel
            app.ModelInfoLabel = uilabel(app.InputPanel);
            app.ModelInfoLabel.FontSize = 12;
            app.ModelInfoLabel.WordWrap = 'on';
            app.ModelInfoLabel.VerticalAlignment = 'top';
            app.ModelInfoLabel.Position = [16 466 340 80];
            app.ModelInfoLabel.Text = '';

            % Create LoadDatasetButton
            app.LoadDatasetButton = uibutton(app.InputPanel, 'push');
            app.LoadDatasetButton.ButtonPushedFcn = createCallbackFcn(app, @LoadDatasetButtonPushed, true);
            app.LoadDatasetButton.FontSize = 12;
            app.LoadDatasetButton.Position = [16 418 160 36];
            app.LoadDatasetButton.Text = 'Učitaj dataset';

            % Create DatasetPathLabel
            app.DatasetPathLabel = uilabel(app.InputPanel);
            app.DatasetPathLabel.FontName = 'Courier New';
            app.DatasetPathLabel.FontSize = 11;
            app.DatasetPathLabel.WordWrap = 'on';
            app.DatasetPathLabel.VerticalAlignment = 'top';
            app.DatasetPathLabel.Position = [16 366 340 44];
            app.DatasetPathLabel.Text = '';

            % Create ImportPredictionsButton
            app.ImportPredictionsButton = uibutton(app.InputPanel, 'push');
            app.ImportPredictionsButton.ButtonPushedFcn = createCallbackFcn(app, @ImportPredictionsButtonPushed, true);
            app.ImportPredictionsButton.FontSize = 12;
            app.ImportPredictionsButton.Position = [16 310 160 36];
            app.ImportPredictionsButton.Text = 'Uvezi yTrue/yPred';

            % Create PredSourceLabel
            app.PredSourceLabel = uilabel(app.InputPanel);
            app.PredSourceLabel.FontSize = 12;
            app.PredSourceLabel.WordWrap = 'on';
            app.PredSourceLabel.VerticalAlignment = 'top';
            app.PredSourceLabel.Position = [16 242 340 56];
            app.PredSourceLabel.Text = '';

            % Create ExportPredictionsButton
            app.ExportPredictionsButton = uibutton(app.InputPanel, 'push');
            app.ExportPredictionsButton.ButtonPushedFcn = createCallbackFcn(app, @ExportPredictionsButtonPushed, true);
            app.ExportPredictionsButton.FontSize = 12;
            app.ExportPredictionsButton.Position = [16 194 160 36];
            app.ExportPredictionsButton.Text = 'Izvezi CSV';

            % Create HintLabel
            app.HintLabel = uilabel(app.InputPanel);
            app.HintLabel.FontSize = 12;
            app.HintLabel.FontColor = [0.40 0.40 0.40];
            app.HintLabel.WordWrap = 'on';
            app.HintLabel.VerticalAlignment = 'top';
            app.HintLabel.Position = [16 90 340 88];
            app.HintLabel.Text = 'Modeli sačuvani treniranjem u PhotoLab-u već sadrže predikcije na test skupu. Stariji modeli traže dataset (folder sa photolab_dataset.mat) koji se klasifikuje na isti način kao pri treniranju.';

            % Create ComputeMetricsButton
            app.ComputeMetricsButton = uibutton(app.InputPanel, 'push');
            app.ComputeMetricsButton.ButtonPushedFcn = createCallbackFcn(app, @ComputeMetricsButtonPushed, true);
            app.ComputeMetricsButton.BackgroundColor = [0.20 0.45 0.75];
            app.ComputeMetricsButton.FontColor = [1 1 1];
            app.ComputeMetricsButton.FontSize = 13;
            app.ComputeMetricsButton.FontWeight = 'bold';
            app.ComputeMetricsButton.Position = [16 16 200 44];
            app.ComputeMetricsButton.Text = 'Izračunaj metrike';

            %% Metrike

            % Create MetricsPanel
            app.MetricsPanel = uipanel(app.UIFigure);
            app.MetricsPanel.Title = 'Metrike';
            app.MetricsPanel.FontSize = 14;
            app.MetricsPanel.FontWeight = 'bold';
            app.MetricsPanel.Position = [412 588 764 96];

            % Create AccuracyCaptionLabel
            app.AccuracyCaptionLabel = uilabel(app.MetricsPanel);
            app.AccuracyCaptionLabel.FontSize = 12;
            app.AccuracyCaptionLabel.Position = [16 8 170 22];
            app.AccuracyCaptionLabel.Text = 'Tačnost';

            % Create AccuracyValueLabel
            app.AccuracyValueLabel = uilabel(app.MetricsPanel);
            app.AccuracyValueLabel.FontSize = 20;
            app.AccuracyValueLabel.FontWeight = 'bold';
            app.AccuracyValueLabel.FontColor = [0.18 0.55 0.34];
            app.AccuracyValueLabel.Position = [16 32 170 32];
            app.AccuracyValueLabel.Text = '—';

            % Create PrecisionCaptionLabel
            app.PrecisionCaptionLabel = uilabel(app.MetricsPanel);
            app.PrecisionCaptionLabel.FontSize = 12;
            app.PrecisionCaptionLabel.Position = [200 8 170 22];
            app.PrecisionCaptionLabel.Text = 'Makro precision';

            % Create PrecisionValueLabel
            app.PrecisionValueLabel = uilabel(app.MetricsPanel);
            app.PrecisionValueLabel.FontSize = 20;
            app.PrecisionValueLabel.FontWeight = 'bold';
            app.PrecisionValueLabel.FontColor = [0.18 0.55 0.34];
            app.PrecisionValueLabel.Position = [200 32 170 32];
            app.PrecisionValueLabel.Text = '—';

            % Create RecallCaptionLabel
            app.RecallCaptionLabel = uilabel(app.MetricsPanel);
            app.RecallCaptionLabel.FontSize = 12;
            app.RecallCaptionLabel.Position = [384 8 170 22];
            app.RecallCaptionLabel.Text = 'Makro recall';

            % Create RecallValueLabel
            app.RecallValueLabel = uilabel(app.MetricsPanel);
            app.RecallValueLabel.FontSize = 20;
            app.RecallValueLabel.FontWeight = 'bold';
            app.RecallValueLabel.FontColor = [0.18 0.55 0.34];
            app.RecallValueLabel.Position = [384 32 170 32];
            app.RecallValueLabel.Text = '—';

            % Create F1CaptionLabel
            app.F1CaptionLabel = uilabel(app.MetricsPanel);
            app.F1CaptionLabel.FontSize = 12;
            app.F1CaptionLabel.Position = [568 8 170 22];
            app.F1CaptionLabel.Text = 'Makro F1';

            % Create F1ValueLabel
            app.F1ValueLabel = uilabel(app.MetricsPanel);
            app.F1ValueLabel.FontSize = 20;
            app.F1ValueLabel.FontWeight = 'bold';
            app.F1ValueLabel.FontColor = [0.18 0.55 0.34];
            app.F1ValueLabel.Position = [568 32 170 32];
            app.F1ValueLabel.Text = '—';

            %% Matrica konfuzije

            % Create ConfusionPanel
            app.ConfusionPanel = uipanel(app.UIFigure);
            app.ConfusionPanel.Title = 'Matrica konfuzije';
            app.ConfusionPanel.FontSize = 14;
            app.ConfusionPanel.FontWeight = 'bold';
            app.ConfusionPanel.Position = [412 296 374 276];

            % Create ConfusionMatrixAxes
            app.ConfusionMatrixAxes = uiaxes(app.ConfusionPanel);
            app.ConfusionMatrixAxes.Position = [8 8 358 242];

            %% Metrike po klasi

            % Create PerClassPanel
            app.PerClassPanel = uipanel(app.UIFigure);
            app.PerClassPanel.Title = 'Metrike po klasi';
            app.PerClassPanel.FontSize = 14;
            app.PerClassPanel.FontWeight = 'bold';
            app.PerClassPanel.Position = [802 296 374 276];

            % Create BarChartAxes
            app.BarChartAxes = uiaxes(app.PerClassPanel);
            app.BarChartAxes.Position = [8 8 358 242];

            %% Najčešće zabune

            % Create ConfusionsPanel
            app.ConfusionsPanel = uipanel(app.UIFigure);
            app.ConfusionsPanel.Title = 'Najčešće zabune (stvarna → predviđena klasa)';
            app.ConfusionsPanel.FontSize = 14;
            app.ConfusionsPanel.FontWeight = 'bold';
            app.ConfusionsPanel.Position = [412 24 764 256];

            % Create ConfusionsTable
            app.ConfusionsTable = uitable(app.ConfusionsPanel);
            app.ConfusionsTable.ColumnName = {'Stvarna'; 'Predviđena'; 'Broj'};
            app.ConfusionsTable.ColumnWidth = {'auto', 'auto', 100};
            app.ConfusionsTable.RowName = {};
            app.ConfusionsTable.FontSize = 12;
            app.ConfusionsTable.Position = [16 16 732 198];

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = EvaluationMetricsApp

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
