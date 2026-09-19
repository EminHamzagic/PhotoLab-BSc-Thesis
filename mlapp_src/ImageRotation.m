classdef ImageRotation < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure            matlab.ui.Figure
        TitleLabel          matlab.ui.control.Label
        ControlsPanel       matlab.ui.container.Panel
        UgaoSliderLabel     matlab.ui.control.Label
        UgaoSlider          matlab.ui.control.Slider
        AngleValueLabel     matlab.ui.control.Label
        OriginalPanel       matlab.ui.container.Panel
        Original            matlab.ui.control.Image
        RotatedPanel        matlab.ui.container.Panel
        Rotated             matlab.ui.control.Image
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

        % Value changing function: UgaoSlider
        function UgaoSliderValueChanging(app, event)
            if isempty(app.LoadedImage)
                uialert(app.UIFigure, 'Morate izabrati sliku prvo!', 'Warning');
                return;
            end
            changingValue = event.Value;
            app.AngleValueLabel.Text = sprintf('%.0f °', changingValue);
            app.Rotated.ImageSource = imrotate(app.LoadedImage, changingValue, 'bilinear', 'crop');
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 900 620];
            app.UIFigure.Name = 'Rotacija slike';

            % Create TitleLabel
            app.TitleLabel = uilabel(app.UIFigure);
            app.TitleLabel.FontSize = 22;
            app.TitleLabel.FontWeight = 'bold';
            app.TitleLabel.Position = [24 564 852 32];
            app.TitleLabel.Text = 'Rotacija slike';

            % Create ControlsPanel
            app.ControlsPanel = uipanel(app.UIFigure);
            app.ControlsPanel.Title = 'Rotacija';
            app.ControlsPanel.FontSize = 14;
            app.ControlsPanel.FontWeight = 'bold';
            app.ControlsPanel.Position = [24 24 232 516];

            % Create UgaoSliderLabel
            app.UgaoSliderLabel = uilabel(app.ControlsPanel);
            app.UgaoSliderLabel.FontSize = 13;
            app.UgaoSliderLabel.Position = [16 452 200 22];
            app.UgaoSliderLabel.Text = 'Ugao rotacije';

            % Create AngleValueLabel
            app.AngleValueLabel = uilabel(app.ControlsPanel);
            app.AngleValueLabel.FontSize = 20;
            app.AngleValueLabel.FontWeight = 'bold';
            app.AngleValueLabel.FontColor = [0.18 0.55 0.34];
            app.AngleValueLabel.Position = [16 408 200 32];
            app.AngleValueLabel.Text = '0 °';

            % Create UgaoSlider
            app.UgaoSlider = uislider(app.ControlsPanel);
            app.UgaoSlider.Limits = [-180 180];
            app.UgaoSlider.MajorTicks = [-180 0 180];
            app.UgaoSlider.ValueChangingFcn = createCallbackFcn(app, @UgaoSliderValueChanging, true);
            app.UgaoSlider.FontSize = 12;
            app.UgaoSlider.Position = [24 384 184 3];

            % Create OriginalPanel
            app.OriginalPanel = uipanel(app.UIFigure);
            app.OriginalPanel.Title = 'Originalna slika';
            app.OriginalPanel.FontSize = 14;
            app.OriginalPanel.FontWeight = 'bold';
            app.OriginalPanel.Position = [272 290 604 250];

            % Create Original
            app.Original = uiimage(app.OriginalPanel);
            app.Original.Position = [16 12 572 204];

            % Create RotatedPanel
            app.RotatedPanel = uipanel(app.UIFigure);
            app.RotatedPanel.Title = 'Rotirana slika';
            app.RotatedPanel.FontSize = 14;
            app.RotatedPanel.FontWeight = 'bold';
            app.RotatedPanel.Position = [272 24 604 250];

            % Create Rotated
            app.Rotated = uiimage(app.RotatedPanel);
            app.Rotated.Position = [16 12 572 204];

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = ImageRotation

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
