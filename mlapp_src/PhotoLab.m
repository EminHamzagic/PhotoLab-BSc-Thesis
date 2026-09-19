classdef PhotoLab < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                 matlab.ui.Figure
        DeepLearningzaanalizuslikeButton  matlab.ui.control.Button
        ObradislikeButton        matlab.ui.control.Button
        DobrodoliuPhotoLabLabel  matlab.ui.control.Label
        PhotoLabLabel            matlab.ui.control.Label
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Button pushed function: ObradislikeButton
        function ObradislikeButtonPushed(app, event)
            optionsWindows = Options();
            appDir = fileparts(mfilename('fullpath'));

            % Add desired subfolders relative to the app location
            addpath(fullfile(appDir, 'cnn_ui'));
            addpath(fullfile(appDir, 'options_ui'));
            addpath(fullfile(appDir, 'scripts'));
            addpath(fullfile(appDir, 'metrics'));
            addpath(fullfile(appDir, 'generative'));
            addpath(genpath(fullfile(appDir, 'utils')));
            savepath;
        end

        % Button pushed function: DeepLearningzaanalizuslikeButton
        function DeepLearningzaanalizuslikeButtonPushed(app, event)
            cnn_menu = cnn_Menu();
            appDir = fileparts(mfilename('fullpath'));

            % Add desired subfolders relative to the app location
            addpath(fullfile(appDir, 'cnn_ui'));
            addpath(fullfile(appDir, 'options_ui'));
            addpath(fullfile(appDir, 'scripts'));
            addpath(fullfile(appDir, 'metrics'));
            addpath(fullfile(appDir, 'generative'));
            addpath(genpath(fullfile(appDir, 'utils')));
            savepath;
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 925 666];
            app.UIFigure.Name = 'MATLAB App';

            % Create PhotoLabLabel
            app.PhotoLabLabel = uilabel(app.UIFigure);
            app.PhotoLabLabel.FontSize = 36;
            app.PhotoLabLabel.Position = [388 575 159 47];
            app.PhotoLabLabel.Text = 'PhotoLab';

            % Create DobrodoliuPhotoLabLabel
            app.DobrodoliuPhotoLabLabel = uilabel(app.UIFigure);
            app.DobrodoliuPhotoLabLabel.HorizontalAlignment = 'center';
            app.DobrodoliuPhotoLabLabel.WordWrap = 'on';
            app.DobrodoliuPhotoLabLabel.FontSize = 18;
            app.DobrodoliuPhotoLabLabel.Position = [93 437 751 111];
            app.DobrodoliuPhotoLabLabel.Text = {''; 'PhotoLab je intuitivna aplikacija za obradu i uređivanje slika, dizajnirana kako za početnike, tako i za profesionalce. Svojim modernim alatima za retuširanje, prilagođavanje boja, dodavanje efekata i poboljšavanje kvalitete fotografija, PhotoLab omogućuje brzo i jednostavno pretvaranje svakodnevnih slika u impresivna umetnička dela.'};

            % Create ObradislikeButton
            app.ObradislikeButton = uibutton(app.UIFigure, 'push');
            app.ObradislikeButton.ButtonPushedFcn = createCallbackFcn(app, @ObradislikeButtonPushed, true);
            app.ObradislikeButton.FontSize = 24;
            app.ObradislikeButton.Position = [397 315 142 39];
            app.ObradislikeButton.Text = 'Obradi slike';

            % Create DeepLearningzaanalizuslikeButton
            app.DeepLearningzaanalizuslikeButton = uibutton(app.UIFigure, 'push');
            app.DeepLearningzaanalizuslikeButton.ButtonPushedFcn = createCallbackFcn(app, @DeepLearningzaanalizuslikeButtonPushed, true);
            app.DeepLearningzaanalizuslikeButton.FontSize = 24;
            app.DeepLearningzaanalizuslikeButton.Position = [279 230 381 53];
            app.DeepLearningzaanalizuslikeButton.Text = 'Deep Learning za analizu slike';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = PhotoLab

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