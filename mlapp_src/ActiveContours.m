classdef ActiveContours < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                     matlab.ui.Figure
        TitleLabel                   matlab.ui.control.Label
        ControlsPanel                matlab.ui.container.Panel
        MaskSectionLabel             matlab.ui.control.Label
        MaskShapeDropDownLabel       matlab.ui.control.Label
        MaskShapeDropDown            matlab.ui.control.DropDown
        AlgoSectionLabel             matlab.ui.control.Label
        IterationSliderLabel         matlab.ui.control.Label
        IterationSlider              matlab.ui.control.Slider
        StopCriterionEditFieldLabel  matlab.ui.control.Label
        StopCriterionEditField       matlab.ui.control.NumericEditField
        RunSegmentationButton        matlab.ui.control.Button
        OriginalPanel                matlab.ui.container.Panel
        Original                     matlab.ui.control.Image
        MaskPanel                    matlab.ui.container.Panel
        SegmentedImage               matlab.ui.control.Image
        ConvertedPanel               matlab.ui.container.Panel
        Converted                    matlab.ui.control.Image
    end

    properties (Access = private)
        LoadedImage % Slika prosleđena iz Options prozora
        Mask % Početna maska za Chan-Vese algoritam
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

        % Value changed function: MaskShapeDropDown
        function MaskShapeDropDownValueChanged(app, event)
            % Check if image is loaded
            if isempty(app.LoadedImage)
                uialert(app.UIFigure, 'Morate izabrati sliku prvo!', 'Warning');
                return;
            end

            % Get image dimensions
            [height, width, ~] = size(app.LoadedImage);

            % Create mask based on user selection
            if strcmp(app.MaskShapeDropDown.Value, 'Rectangle')
                app.Mask = false(height, width);
                h_start = round(height/4);
                h_end = round(3*height/4);
                w_start = round(width/4);
                w_end = round(3*width/4);
                app.Mask(h_start:h_end, w_start:w_end) = true;
            elseif strcmp(app.MaskShapeDropDown.Value, 'Ellipse')
                [rows, cols] = ndgrid(1:height, 1:width);
                center = [round(height/2), round(width/2)];
                radius = min(round(height/3), round(width/3));
                app.Mask = (rows - center(1)).^2 + (cols - center(2)).^2 <= radius^2;
            end

            % Create overlay image
            overlay = app.LoadedImage;
            if size(overlay, 3) == 1
                overlay = repmat(overlay, [1 1 3]);
            end

            % Create red mask overlay
            mask_overlay = zeros(size(overlay));
            mask_overlay(:,:,1) = app.Mask * 255;  % Red channel

            % Blend original image with mask
            alpha = 0.3;  % Transparency level
            blended = uint8(double(overlay) .* (1-alpha) + double(mask_overlay) .* alpha);

            % Display result in Image component
            app.SegmentedImage.ImageSource = blended;
        end

        % Button pushed function: RunSegmentationButton
        function RunSegmentationButtonPushed(app, event)
            % Check if the image and mask are defined
            if isempty(app.LoadedImage) || isempty(app.Mask)
                uialert(app.UIFigure, 'Postavite masku pre pokretanja algoritma.', 'Warning');
                return;
            end

            % Get current values from UI controls
            maxIterations = round(app.IterationSlider.Value);
            stopCriterion = app.StopCriterionEditField.Value;

            % Set a reasonable default value if the stop criterion is not valid
            if isempty(stopCriterion) || ~isfinite(stopCriterion)
                stopCriterion = 0.5;
            end

            app.RunSegmentationButton.Enable = 'off';
            try
                % Perform the segmentation
                segmented = activecontour(app.LoadedImage, app.Mask, maxIterations, 'Chan-Vese', 'SmoothFactor', stopCriterion);

                % Convert logical to uint8 for proper display
                segmentedImage = uint8(segmented) * 255;

                % If the original image is RGB, replicate the mask for all channels
                if size(app.LoadedImage, 3) == 3
                    segmentedImage = repmat(segmentedImage, [1 1 3]);
                end

                % Update the display directly without saving to file
                app.Converted.ImageSource = segmentedImage;

                % Force a refresh of the display
                drawnow;

            catch ME
                % Handle any errors that might occur during segmentation
                uialert(app.UIFigure, ['Segmentacija nije uspela: ' ME.message], 'Greška');
            end
            app.RunSegmentationButton.Enable = 'on';
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 1200 760];
            app.UIFigure.Name = 'Active Contours segmentacija';

            % Create TitleLabel
            app.TitleLabel = uilabel(app.UIFigure);
            app.TitleLabel.FontSize = 22;
            app.TitleLabel.FontWeight = 'bold';
            app.TitleLabel.Position = [24 704 1152 32];
            app.TitleLabel.Text = 'Active Contours segmentacija';

            % Create ControlsPanel
            app.ControlsPanel = uipanel(app.UIFigure);
            app.ControlsPanel.Title = 'Parametri';
            app.ControlsPanel.FontSize = 14;
            app.ControlsPanel.FontWeight = 'bold';
            app.ControlsPanel.Position = [24 24 372 664];

            % Create MaskSectionLabel
            app.MaskSectionLabel = uilabel(app.ControlsPanel);
            app.MaskSectionLabel.FontSize = 13;
            app.MaskSectionLabel.Position = [16 600 340 22];
            app.MaskSectionLabel.Text = 'Početna maska';

            % Create MaskShapeDropDownLabel
            app.MaskShapeDropDownLabel = uilabel(app.ControlsPanel);
            app.MaskShapeDropDownLabel.FontSize = 12;
            app.MaskShapeDropDownLabel.Position = [16 560 130 24];
            app.MaskShapeDropDownLabel.Text = 'Oblik maske:';

            % Create MaskShapeDropDown
            app.MaskShapeDropDown = uidropdown(app.ControlsPanel);
            app.MaskShapeDropDown.Items = {'Ellipse', 'Rectangle'};
            app.MaskShapeDropDown.ValueChangedFcn = createCallbackFcn(app, @MaskShapeDropDownValueChanged, true);
            app.MaskShapeDropDown.FontSize = 12;
            app.MaskShapeDropDown.Position = [150 560 190 24];
            app.MaskShapeDropDown.Value = 'Ellipse';

            % Create AlgoSectionLabel
            app.AlgoSectionLabel = uilabel(app.ControlsPanel);
            app.AlgoSectionLabel.FontSize = 13;
            app.AlgoSectionLabel.Position = [16 500 340 22];
            app.AlgoSectionLabel.Text = 'Algoritam (Chan-Vese)';

            % Create IterationSliderLabel
            app.IterationSliderLabel = uilabel(app.ControlsPanel);
            app.IterationSliderLabel.FontSize = 12;
            app.IterationSliderLabel.Position = [16 460 200 24];
            app.IterationSliderLabel.Text = 'Broj iteracija:';

            % Create IterationSlider
            app.IterationSlider = uislider(app.ControlsPanel);
            app.IterationSlider.Limits = [10 500];
            app.IterationSlider.FontSize = 12;
            app.IterationSlider.Position = [24 440 324 3];
            app.IterationSlider.Value = 10;

            % Create StopCriterionEditFieldLabel
            app.StopCriterionEditFieldLabel = uilabel(app.ControlsPanel);
            app.StopCriterionEditFieldLabel.FontSize = 12;
            app.StopCriterionEditFieldLabel.Position = [16 380 130 24];
            app.StopCriterionEditFieldLabel.Text = 'Faktor glatkoće:';

            % Create StopCriterionEditField
            app.StopCriterionEditField = uieditfield(app.ControlsPanel, 'numeric');
            app.StopCriterionEditField.FontSize = 12;
            app.StopCriterionEditField.Position = [150 380 100 24];
            app.StopCriterionEditField.Value = 0.5;

            % Create RunSegmentationButton
            app.RunSegmentationButton = uibutton(app.ControlsPanel, 'push');
            app.RunSegmentationButton.ButtonPushedFcn = createCallbackFcn(app, @RunSegmentationButtonPushed, true);
            app.RunSegmentationButton.BackgroundColor = [0.2 0.45 0.75];
            app.RunSegmentationButton.FontSize = 13;
            app.RunSegmentationButton.FontWeight = 'bold';
            app.RunSegmentationButton.FontColor = [1 1 1];
            app.RunSegmentationButton.Position = [156 16 200 44];
            app.RunSegmentationButton.Text = 'Pokreni segmentaciju';

            % Create OriginalPanel
            app.OriginalPanel = uipanel(app.UIFigure);
            app.OriginalPanel.Title = 'Originalna slika';
            app.OriginalPanel.FontSize = 14;
            app.OriginalPanel.FontWeight = 'bold';
            app.OriginalPanel.Position = [412 364 374 324];

            % Create Original
            app.Original = uiimage(app.OriginalPanel);
            app.Original.Position = [16 12 342 278];

            % Create MaskPanel
            app.MaskPanel = uipanel(app.UIFigure);
            app.MaskPanel.Title = 'Maska (pregled)';
            app.MaskPanel.FontSize = 14;
            app.MaskPanel.FontWeight = 'bold';
            app.MaskPanel.Position = [802 364 374 324];

            % Create SegmentedImage
            app.SegmentedImage = uiimage(app.MaskPanel);
            app.SegmentedImage.Position = [16 12 342 278];

            % Create ConvertedPanel
            app.ConvertedPanel = uipanel(app.UIFigure);
            app.ConvertedPanel.Title = 'Segmentirana slika';
            app.ConvertedPanel.FontSize = 14;
            app.ConvertedPanel.FontWeight = 'bold';
            app.ConvertedPanel.Position = [412 24 764 324];

            % Create Converted
            app.Converted = uiimage(app.ConvertedPanel);
            app.Converted.Position = [16 12 732 278];

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = ActiveContours

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
