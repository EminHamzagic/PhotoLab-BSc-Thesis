classdef GreyScaleConversion < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure            matlab.ui.Figure
        TitleLabel          matlab.ui.control.Label
        ControlsPanel       matlab.ui.container.Panel
        SectionLabel        matlab.ui.control.Label
        RGBButton           matlab.ui.control.Button
        GreyScaleButton     matlab.ui.control.Button
        OriginalPanel       matlab.ui.container.Panel
        Original            matlab.ui.control.Image
        ConvertedPanel      matlab.ui.container.Panel
        Converted           matlab.ui.control.Image
    end

    properties (Access = private)
        LoadedImage % Slika prosleđena iz Options prozora
    end

    methods (Access = public)

        function loadImage(app, image)
            app.LoadedImage = image;
            app.Original.ImageSource = image;
        end
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            movegui(app.UIFigure, 'center');
        end

        % Button pushed function: RGBButton
        function RGBButtonPushed(app, event)
            app.Converted.ImageSource = app.LoadedImage;
        end

        % Button pushed function: GreyScaleButton
        function GreyScaleButtonPushed(app, event)
            gsImage = rgb2gray(app.LoadedImage);
            % da bi konvertovao u 3-channel format jer imagesource to
            % ocekuje
            gsImage = repmat(gsImage, [1 1 3]);
            app.Converted.ImageSource = gsImage;
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 900 620];
            app.UIFigure.Name = 'Konverzija u crno-belu sliku';

            % Create TitleLabel
            app.TitleLabel = uilabel(app.UIFigure);
            app.TitleLabel.FontSize = 22;
            app.TitleLabel.FontWeight = 'bold';
            app.TitleLabel.Position = [24 564 852 32];
            app.TitleLabel.Text = 'Konverzija u crno-belu sliku';

            % Create ControlsPanel
            app.ControlsPanel = uipanel(app.UIFigure);
            app.ControlsPanel.Title = 'Konverzija';
            app.ControlsPanel.FontSize = 14;
            app.ControlsPanel.FontWeight = 'bold';
            app.ControlsPanel.Position = [24 24 232 516];

            % Create SectionLabel
            app.SectionLabel = uilabel(app.ControlsPanel);
            app.SectionLabel.FontSize = 13;
            app.SectionLabel.Position = [16 452 200 22];
            app.SectionLabel.Text = 'Odaberi konverziju';

            % Create RGBButton
            app.RGBButton = uibutton(app.ControlsPanel, 'push');
            app.RGBButton.ButtonPushedFcn = createCallbackFcn(app, @RGBButtonPushed, true);
            app.RGBButton.FontSize = 12;
            app.RGBButton.Position = [16 400 160 36];
            app.RGBButton.Text = 'Originalna (RGB)';

            % Create GreyScaleButton
            app.GreyScaleButton = uibutton(app.ControlsPanel, 'push');
            app.GreyScaleButton.ButtonPushedFcn = createCallbackFcn(app, @GreyScaleButtonPushed, true);
            app.GreyScaleButton.BackgroundColor = [0.2 0.45 0.75];
            app.GreyScaleButton.FontSize = 13;
            app.GreyScaleButton.FontWeight = 'bold';
            app.GreyScaleButton.FontColor = [1 1 1];
            app.GreyScaleButton.Position = [16 16 200 44];
            app.GreyScaleButton.Text = 'Crno-bela (GreyScale)';

            % Create OriginalPanel
            app.OriginalPanel = uipanel(app.UIFigure);
            app.OriginalPanel.Title = 'Originalna slika';
            app.OriginalPanel.FontSize = 14;
            app.OriginalPanel.FontWeight = 'bold';
            app.OriginalPanel.Position = [272 290 604 250];

            % Create Original
            app.Original = uiimage(app.OriginalPanel);
            app.Original.Position = [16 12 572 204];

            % Create ConvertedPanel
            app.ConvertedPanel = uipanel(app.UIFigure);
            app.ConvertedPanel.Title = 'Konvertovana slika';
            app.ConvertedPanel.FontSize = 14;
            app.ConvertedPanel.FontWeight = 'bold';
            app.ConvertedPanel.Position = [272 24 604 250];

            % Create Converted
            app.Converted = uiimage(app.ConvertedPanel);
            app.Converted.Position = [16 12 572 204];

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = GreyScaleConversion

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
