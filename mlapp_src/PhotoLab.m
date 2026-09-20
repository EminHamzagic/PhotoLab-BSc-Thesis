classdef PhotoLab < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                 matlab.ui.Figure
        DeepLearningzaanalizuslikeButton  matlab.ui.control.Button
        ObradislikeButton        matlab.ui.control.Button
        DobrodoliuPhotoLabLabel  matlab.ui.control.Label
        PhotoLabLabel            matlab.ui.control.Label
        ModulesPanel             matlab.ui.container.Panel
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            movegui(app.UIFigure, 'center');
        end

        % Button pushed function: ObradislikeButton
        function ObradislikeButtonPushed(app, event)
            optionsWindows = Options();
            appDir = fileparts(mfilename('fullpath'));

            % Add desired subfolders relative to the app location
            addpath(fullfile(appDir, 'cnn_ui'));
            addpath(fullfile(appDir, 'options_ui'));
            addpath(fullfile(appDir, 'scripts'));
            addpath(fullfile(appDir, 'metrics'));
            addpath(fullfile(appDir, 'cnn_core'));
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
            addpath(fullfile(appDir, 'cnn_core'));
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
            app.UIFigure.Position = [100 100 900 620];
            app.UIFigure.Name = 'PhotoLab';

            % Create PhotoLabLabel
            app.PhotoLabLabel = uilabel(app.UIFigure);
            app.PhotoLabLabel.FontSize = 36;
            app.PhotoLabLabel.FontWeight = 'bold';
            app.PhotoLabLabel.Position = [24 540 852 48];
            app.PhotoLabLabel.Text = 'PhotoLab';

            % Create DobrodoliuPhotoLabLabel
            app.DobrodoliuPhotoLabLabel = uilabel(app.UIFigure);
            app.DobrodoliuPhotoLabLabel.FontSize = 13;
            app.DobrodoliuPhotoLabLabel.WordWrap = 'on';
            app.DobrodoliuPhotoLabLabel.VerticalAlignment = 'top';
            app.DobrodoliuPhotoLabLabel.Position = [24 456 852 72];
            app.DobrodoliuPhotoLabLabel.Text = 'PhotoLab je intuitivna aplikacija za obradu i uređivanje slika, dizajnirana kako za početnike, tako i za profesionalce. Svojim modernim alatima za retuširanje, prilagođavanje boja, dodavanje efekata i poboljšavanje kvalitete fotografija, PhotoLab omogućuje brzo i jednostavno pretvaranje svakodnevnih slika u impresivna umetnička dela.';

            % Create ModulesPanel
            app.ModulesPanel = uipanel(app.UIFigure);
            app.ModulesPanel.Title = 'Moduli';
            app.ModulesPanel.FontSize = 14;
            app.ModulesPanel.FontWeight = 'bold';
            app.ModulesPanel.Position = [24 280 852 140];

            % Create ObradislikeButton
            app.ObradislikeButton = uibutton(app.ModulesPanel, 'push');
            app.ObradislikeButton.ButtonPushedFcn = createCallbackFcn(app, @ObradislikeButtonPushed, true);
            app.ObradislikeButton.FontSize = 14;
            app.ObradislikeButton.WordWrap = 'on';
            app.ObradislikeButton.Position = [16 40 280 56];
            app.ObradislikeButton.Text = 'Obradi slike';

            % Create DeepLearningzaanalizuslikeButton
            app.DeepLearningzaanalizuslikeButton = uibutton(app.ModulesPanel, 'push');
            app.DeepLearningzaanalizuslikeButton.ButtonPushedFcn = createCallbackFcn(app, @DeepLearningzaanalizuslikeButtonPushed, true);
            app.DeepLearningzaanalizuslikeButton.FontSize = 14;
            app.DeepLearningzaanalizuslikeButton.WordWrap = 'on';
            app.DeepLearningzaanalizuslikeButton.Position = [312 40 280 56];
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