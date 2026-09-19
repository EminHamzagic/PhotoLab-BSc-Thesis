classdef HarrisCornerDetectionFeature < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                         matlab.ui.Figure
        TitleLabel                       matlab.ui.control.Label
        ControlsPanel                    matlab.ui.container.Panel
        SectionLabel                     matlab.ui.control.Label
        SliderzapodeavanjepragaLabel     matlab.ui.control.Label
        Sliderzapodeavanjepraga          matlab.ui.control.Slider
        Threshold0Label                  matlab.ui.control.Label
        pokretanjeHarrisalgoritmaButton  matlab.ui.control.Button
        OriginalPanel                    matlab.ui.container.Panel
        Original                         matlab.ui.control.Image
        ResultPanel                      matlab.ui.container.Panel
        UIAxes                           matlab.ui.control.UIAxes
    end

    properties (Access = private)
        LoadedImage % Slika prosleđena iz Options prozora
        sliderValue = 0 % Trenutna vrednost praga
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
            title(app.UIAxes, 'Prikaz slike i rezultata');
            movegui(app.UIFigure, 'center');
        end

        % Value changed function: Sliderzapodeavanjepraga
        function SliderzapodeavanjepragaValueChanged(app, event)
            app.sliderValue = app.Sliderzapodeavanjepraga.Value;
            app.Threshold0Label.Text = sprintf('Prag: %.2f', app.sliderValue);
        end

        % Button pushed function: pokretanjeHarrisalgoritmaButton
        function pokretanjeHarrisalgoritmaButtonPushed(app, event)
            if isempty(app.LoadedImage)
                uialert(app.UIFigure, 'Morate izabrati sliku prvo!', 'Warning');
                return;
            end

            if size(app.LoadedImage, 3) == 3
                grayImage = im2gray(app.LoadedImage);
            else
                grayImage = app.LoadedImage;
            end

            [rows, cols] = size(grayImage);
            grayImage = im2double(grayImage);

            [Ix, Iy] = imgradientxy(grayImage);

            Ix2 = imgaussfilt(Ix.^2, 1);
            Iy2 = imgaussfilt(Iy.^2, 1);
            Ixy = imgaussfilt(Ix .* Iy, 1);

            k = 0.04;
            R = (Ix2 .* Iy2 - Ixy.^2) - k * (Ix2 + Iy2).^2;

            Rmax = max(R(:));
            corners = R > app.sliderValue * Rmax;

            [cornerRows, cornerCols] = find(corners);

            imshow(app.LoadedImage, 'Parent', app.UIAxes);
            hold(app.UIAxes, 'on');
            plot(app.UIAxes, cornerCols, cornerRows, 'ro', 'MarkerSize', 5, 'LineWidth', 1.5);
            hold(app.UIAxes, 'off');
            title(app.UIAxes, 'Detektovani uglovi');
        end

        % Value changing function: Sliderzapodeavanjepraga
        function SliderzapodeavanjepragaValueChanging(app, event)
            app.sliderValue = event.Value;
            app.Threshold0Label.Text = sprintf('Prag: %.2f', app.sliderValue);
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 1200 760];
            app.UIFigure.Name = 'Harris Corner Detection';

            % Create TitleLabel
            app.TitleLabel = uilabel(app.UIFigure);
            app.TitleLabel.FontSize = 22;
            app.TitleLabel.FontWeight = 'bold';
            app.TitleLabel.Position = [24 704 1152 32];
            app.TitleLabel.Text = 'Harris Corner Detection';

            % Create ControlsPanel
            app.ControlsPanel = uipanel(app.UIFigure);
            app.ControlsPanel.Title = 'Parametri';
            app.ControlsPanel.FontSize = 14;
            app.ControlsPanel.FontWeight = 'bold';
            app.ControlsPanel.Position = [24 24 372 664];

            % Create SectionLabel
            app.SectionLabel = uilabel(app.ControlsPanel);
            app.SectionLabel.FontSize = 13;
            app.SectionLabel.Position = [16 600 340 22];
            app.SectionLabel.Text = 'Prag detekcije uglova';

            % Create SliderzapodeavanjepragaLabel
            app.SliderzapodeavanjepragaLabel = uilabel(app.ControlsPanel);
            app.SliderzapodeavanjepragaLabel.FontSize = 12;
            app.SliderzapodeavanjepragaLabel.Position = [16 560 340 24];
            app.SliderzapodeavanjepragaLabel.Text = 'Prag (udeo maksimalnog odziva):';

            % Create Sliderzapodeavanjepraga
            app.Sliderzapodeavanjepraga = uislider(app.ControlsPanel);
            app.Sliderzapodeavanjepraga.Limits = [0 1];
            app.Sliderzapodeavanjepraga.ValueChangedFcn = createCallbackFcn(app, @SliderzapodeavanjepragaValueChanged, true);
            app.Sliderzapodeavanjepraga.ValueChangingFcn = createCallbackFcn(app, @SliderzapodeavanjepragaValueChanging, true);
            app.Sliderzapodeavanjepraga.FontSize = 12;
            app.Sliderzapodeavanjepraga.Position = [24 540 324 3];

            % Create Threshold0Label
            app.Threshold0Label = uilabel(app.ControlsPanel);
            app.Threshold0Label.FontSize = 20;
            app.Threshold0Label.FontWeight = 'bold';
            app.Threshold0Label.FontColor = [0.18 0.55 0.34];
            app.Threshold0Label.Position = [16 472 340 32];
            app.Threshold0Label.Text = 'Prag: 0.00';

            % Create pokretanjeHarrisalgoritmaButton
            app.pokretanjeHarrisalgoritmaButton = uibutton(app.ControlsPanel, 'push');
            app.pokretanjeHarrisalgoritmaButton.ButtonPushedFcn = createCallbackFcn(app, @pokretanjeHarrisalgoritmaButtonPushed, true);
            app.pokretanjeHarrisalgoritmaButton.BackgroundColor = [0.2 0.45 0.75];
            app.pokretanjeHarrisalgoritmaButton.FontSize = 13;
            app.pokretanjeHarrisalgoritmaButton.FontWeight = 'bold';
            app.pokretanjeHarrisalgoritmaButton.FontColor = [1 1 1];
            app.pokretanjeHarrisalgoritmaButton.Position = [156 16 200 44];
            app.pokretanjeHarrisalgoritmaButton.Text = 'Pokreni Harris algoritam';

            % Create OriginalPanel
            app.OriginalPanel = uipanel(app.UIFigure);
            app.OriginalPanel.Title = 'Originalna slika';
            app.OriginalPanel.FontSize = 14;
            app.OriginalPanel.FontWeight = 'bold';
            app.OriginalPanel.Position = [412 388 764 300];

            % Create Original
            app.Original = uiimage(app.OriginalPanel);
            app.Original.Position = [16 12 732 254];

            % Create ResultPanel
            app.ResultPanel = uipanel(app.UIFigure);
            app.ResultPanel.Title = 'Detektovani uglovi';
            app.ResultPanel.FontSize = 14;
            app.ResultPanel.FontWeight = 'bold';
            app.ResultPanel.Position = [412 24 764 348];

            % Create UIAxes
            app.UIAxes = uiaxes(app.ResultPanel);
            app.UIAxes.Position = [16 12 732 300];

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = HarrisCornerDetectionFeature

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
