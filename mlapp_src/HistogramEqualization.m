classdef HistogramEqualization < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                     matlab.ui.Figure
        TitleLabel                   matlab.ui.control.Label
        ControlsPanel                matlab.ui.container.Panel
        SectionLabel                 matlab.ui.control.Label
        RGBButton                    matlab.ui.control.Button
        HistogramEqualizationButton  matlab.ui.control.Button
        OriginalPanel                matlab.ui.container.Panel
        Original                     matlab.ui.control.Image
        ConvertedPanel               matlab.ui.container.Panel
        Converted                    matlab.ui.control.Image
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

        % Button pushed function: HistogramEqualizationButton
        function HistogramEqualizationButtonPushed(app, event)
            % metoda razdvajanja kanal posebno uglavnom bolje radi
            r = histeq(app.LoadedImage(:,:,1));
            g = histeq(app.LoadedImage(:,:,2));
            b = histeq(app.LoadedImage(:,:,3));
            eqImage = cat(3, r, g, b);

            app.Converted.ImageSource = eqImage;
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 900 620];
            app.UIFigure.Name = 'Histogram Equalization';

            % Create TitleLabel
            app.TitleLabel = uilabel(app.UIFigure);
            app.TitleLabel.FontSize = 22;
            app.TitleLabel.FontWeight = 'bold';
            app.TitleLabel.Position = [24 564 852 32];
            app.TitleLabel.Text = 'Histogram Equalization';

            % Create ControlsPanel
            app.ControlsPanel = uipanel(app.UIFigure);
            app.ControlsPanel.Title = 'Obrada';
            app.ControlsPanel.FontSize = 14;
            app.ControlsPanel.FontWeight = 'bold';
            app.ControlsPanel.Position = [24 24 232 516];

            % Create SectionLabel
            app.SectionLabel = uilabel(app.ControlsPanel);
            app.SectionLabel.FontSize = 13;
            app.SectionLabel.Position = [16 452 200 22];
            app.SectionLabel.Text = 'Odaberi operaciju';

            % Create RGBButton
            app.RGBButton = uibutton(app.ControlsPanel, 'push');
            app.RGBButton.ButtonPushedFcn = createCallbackFcn(app, @RGBButtonPushed, true);
            app.RGBButton.FontSize = 12;
            app.RGBButton.Position = [16 400 160 36];
            app.RGBButton.Text = 'Originalna (RGB)';

            % Create HistogramEqualizationButton
            app.HistogramEqualizationButton = uibutton(app.ControlsPanel, 'push');
            app.HistogramEqualizationButton.ButtonPushedFcn = createCallbackFcn(app, @HistogramEqualizationButtonPushed, true);
            app.HistogramEqualizationButton.BackgroundColor = [0.2 0.45 0.75];
            app.HistogramEqualizationButton.WordWrap = 'on';
            app.HistogramEqualizationButton.FontSize = 13;
            app.HistogramEqualizationButton.FontWeight = 'bold';
            app.HistogramEqualizationButton.FontColor = [1 1 1];
            app.HistogramEqualizationButton.Position = [16 16 200 44];
            app.HistogramEqualizationButton.Text = 'Histogram Equalization';

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
            app.ConvertedPanel.Title = 'Obrađena slika';
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
        function app = HistogramEqualization

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
