classdef EvaluationMetricsApp < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                  matlab.ui.Figure
        PredictionFileLabel       matlab.ui.control.Label
        FajlLabel                 matlab.ui.control.Label
        MetricsTextArea           matlab.ui.control.TextArea
        ObjasnjenjeTextAreaLabel  matlab.ui.control.Label
        EvaluationMetricsPanel    matlab.ui.container.Panel
        ComputeMetricsButton      matlab.ui.control.Button
        LoadPredictionsButton     matlab.ui.control.Button
        BarChartAxes              matlab.ui.control.UIAxes
        ConfusionMatrixAxes       matlab.ui.control.UIAxes
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            movegui(app.UIFigure, 'center');
            title(app.ConfusionMatrixAxes, 'confusion matrix');
            xlabel(app.ConfusionMatrixAxes, 'X');
            ylabel(app.ConfusionMatrixAxes, 'Y');
            zlabel(app.ConfusionMatrixAxes, 'Z');
            title(app.BarChartAxes, 'bar chart');
            xlabel(app.BarChartAxes, 'X');
            ylabel(app.BarChartAxes, 'Y');
            zlabel(app.BarChartAxes, 'Z');
        end

        % Button pushed function: LoadPredictionsButton
        function LoadPredictionsButtonPushed(app, event)
           [file, path] = uigetfile({'*.mat;*.csv'}, 'Select Predictions File');
            if isequal(file,0)
                return;
            end
        
            fullpath = fullfile(path, file);
        
            if contains(file, '.mat')
                data = load(fullpath);
                app.UIFigure.UserData.predFileData = data; % sačuvaj ceo fajl u UserData
                % Proveri da li ima yTrue i yPred
                if isfield(data,'yTrue') && isfield(data,'yPred')
                    app.UIFigure.UserData.yTrue = data.yTrue;
                    app.UIFigure.UserData.yPred = data.yPred;
                    app.PredictionFileLabel.Text = file;
                else
                    uialert(app.UIFigure, 'Fajl ne sadrži yTrue i yPred, koristiće se net/accuracy iz modela', 'Info');
                end
            else
                tbl = readtable(fullpath);
                if all(ismember({'yTrue','yPred'}, tbl.Properties.VariableNames))
                    app.UIFigure.UserData.yTrue = tbl.yTrue;
                    app.UIFigure.UserData.yPred = tbl.yPred;
                    app.PredictionFileLabel.Text = file;
                else
                    uialert(app.UIFigure, 'CSV fajl mora imati kolone yTrue i yPred', 'Greška');
                end
            end
        end

        % Button pushed function: ComputeMetricsButton
        function ComputeMetricsButtonPushed(app, event)

            % Provera da li su yTrue i yPred učitani
            if isfield(app.UIFigure.UserData,'yTrue') && isfield(app.UIFigure.UserData,'yPred')
                yTrue = app.UIFigure.UserData.yTrue;
                yPred = app.UIFigure.UserData.yPred;
            else
                % Pokušaj učitati cifarModel.mat
                modelData = load('cifarModel.mat'); % sadrži net
                if ~isfield(modelData, 'net')
                    uialert(app.UIFigure, 'Nema učitanih predikcija niti net u cifarModel.mat!', 'Greška');
                    return;
                end
                net = modelData.net;
        
                % Koristi mali test set (primer: 100 uzoraka)
                if isfield(modelData, 'XTest') && isfield(modelData, 'YTest')
                    XTest = modelData.XTest;
                    YTest = modelData.YTest;
                else
                    % Ako XTest i YTest nisu u fajlu, generiši random za demo
                    numSamples = 100;
                    numClasses = 10;
                    XTest = rand(32,32,3,numSamples);
                    YTest = categorical(randi([0 numClasses-1],numSamples,1));
                end
        
                yTrue = YTest;
                yPred = classify(net, XTest);
            end
        
            % Računanje metrika
            acc = computeAccuracy(yTrue, yPred);
            prec = computePrecision(yTrue, yPred);
            rec = computeRecall(yTrue, yPred);
            f1 = computeF1(yTrue, yPred);
        
            % Confusion matrix na postojećem UIAxes
            cm = confusionmat(yTrue, yPred);
            cla(app.ConfusionMatrixAxes);             
            imagesc(app.ConfusionMatrixAxes, cm);    
            colormap(app.ConfusionMatrixAxes, parula);
            colorbar(app.ConfusionMatrixAxes);
            title(app.ConfusionMatrixAxes, 'Confusion Matrix');
            xlabel(app.ConfusionMatrixAxes, 'Predicted');
            ylabel(app.ConfusionMatrixAxes, 'Actual');
            axis(app.ConfusionMatrixAxes, 'tight');
            classes = unique(yTrue);
            xticks(app.ConfusionMatrixAxes, 1:numel(classes));
            yticks(app.ConfusionMatrixAxes, 1:numel(classes));
            xticklabels(app.ConfusionMatrixAxes, classes);
            yticklabels(app.ConfusionMatrixAxes, classes);
        
            % Bar chart za Precision, Recall, F1
            metricsMat = [prec; rec; f1]';
            cla(app.BarChartAxes);                    
            bar(app.BarChartAxes, metricsMat);
            xticks(app.BarChartAxes, 1:numel(classes));
            xticklabels(app.BarChartAxes, classes);
            legend(app.BarChartAxes, {'Precision','Recall','F1'}, 'Location', 'best');
            ylabel(app.BarChartAxes, 'Score');
            title(app.BarChartAxes, 'Metrics per class');
        
            % Tekstualni prikaz metrika
            app.MetricsTextArea.Value = {
                sprintf('Accuracy: %.2f%%', acc*100),
                sprintf('Mean Precision: %.2f%%', mean(prec)*100),
                sprintf('Mean Recall: %.2f%%', mean(rec)*100),
                sprintf('Mean F1: %.2f%%', mean(f1)*100)
            };
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 927 659];
            app.UIFigure.Name = 'MATLAB App';

            % Create ConfusionMatrixAxes
            app.ConfusionMatrixAxes = uiaxes(app.UIFigure);
            app.ConfusionMatrixAxes.Position = [59 241 326 218];

            % Create BarChartAxes
            app.BarChartAxes = uiaxes(app.UIFigure);
            app.BarChartAxes.Position = [522 241 325 218];

            % Create EvaluationMetricsPanel
            app.EvaluationMetricsPanel = uipanel(app.UIFigure);
            app.EvaluationMetricsPanel.Title = 'Evaluation Metrics';
            app.EvaluationMetricsPanel.Position = [192 524 301 70];

            % Create LoadPredictionsButton
            app.LoadPredictionsButton = uibutton(app.EvaluationMetricsPanel, 'push');
            app.LoadPredictionsButton.ButtonPushedFcn = createCallbackFcn(app, @LoadPredictionsButtonPushed, true);
            app.LoadPredictionsButton.Position = [13 8 109 36];
            app.LoadPredictionsButton.Text = 'Load Predictions';

            % Create ComputeMetricsButton
            app.ComputeMetricsButton = uibutton(app.EvaluationMetricsPanel, 'push');
            app.ComputeMetricsButton.ButtonPushedFcn = createCallbackFcn(app, @ComputeMetricsButtonPushed, true);
            app.ComputeMetricsButton.Position = [151 5 115 39];
            app.ComputeMetricsButton.Text = 'Compute Metrics';

            % Create ObjasnjenjeTextAreaLabel
            app.ObjasnjenjeTextAreaLabel = uilabel(app.UIFigure);
            app.ObjasnjenjeTextAreaLabel.HorizontalAlignment = 'right';
            app.ObjasnjenjeTextAreaLabel.Position = [239 174 68 22];
            app.ObjasnjenjeTextAreaLabel.Text = 'Objasnjenje';

            % Create MetricsTextArea
            app.MetricsTextArea = uitextarea(app.UIFigure);
            app.MetricsTextArea.Position = [322 50 275 148];

            % Create FajlLabel
            app.FajlLabel = uilabel(app.UIFigure);
            app.FajlLabel.FontSize = 20;
            app.FajlLabel.Position = [564 542 43 26];
            app.FajlLabel.Text = 'Fajl:';

            % Create PredictionFileLabel
            app.PredictionFileLabel = uilabel(app.UIFigure);
            app.PredictionFileLabel.FontSize = 18;
            app.PredictionFileLabel.Position = [607 542 240 26];
            app.PredictionFileLabel.Text = '';

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