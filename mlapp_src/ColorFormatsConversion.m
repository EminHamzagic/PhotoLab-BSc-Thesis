classdef ColorFormatsConversion < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                        matlab.ui.Figure
        TitleLabel                      matlab.ui.control.Label
        ControlsPanel                   matlab.ui.container.Panel
        SectionLabel                    matlab.ui.control.Label
        RGBButton                       matlab.ui.control.Button
        HSLButton                       matlab.ui.control.Button
        CIELabButton                    matlab.ui.control.Button
        YCbCrButton                     matlab.ui.control.Button
        PreuzmikonvertovanuslikuButton  matlab.ui.control.Button
        OriginalPanel                   matlab.ui.container.Panel
        Original                        matlab.ui.control.Image
        ConvertedPanel                  matlab.ui.container.Panel
        Converted                       matlab.ui.control.Image
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

        % Button pushed function: HSLButton
        function HSLButtonPushed(app, event)
            hsvImage = rgb2hsv(app.LoadedImage);
            app.Converted.ImageSource = hsvImage;
        end

        % Button pushed function: CIELabButton
        function CIELabButtonPushed(app, event)
            labImage = rgb2lab(app.LoadedImage);
            app.Converted.ImageSource = labImage;
        end

        % Button pushed function: YCbCrButton
        function YCbCrButtonPushed(app, event)
            ycbcrImage = rgb2ycbcr(app.LoadedImage);
            app.Converted.ImageSource = ycbcrImage;
        end

        % Button pushed function: PreuzmikonvertovanuslikuButton
        function PreuzmikonvertovanuslikuButtonPushed(app, event)
            if ~isempty(app.Converted.ImageSource) && isnumeric(app.Converted.ImageSource)
                rgbImage = lab2rgb(app.Converted.ImageSource);

                rgbImageUint8 = im2uint8(rgbImage);

                [filename, pathname] = uiputfile({'*.png';'*.jpg';'*.tif'}, 'Save Image As');
                if isequal(filename,0)
                    disp('User canceled save.');
                else
                    fullFileName = fullfile(pathname, filename);
                    imwrite(rgbImageUint8, fullFileName);
                    disp(['Image saved to ', fullFileName]);
                end
            else
                uialert(app.UIFigure, 'No image found in Converted.ImageSource.', 'Error');
            end
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 1200 760];
            app.UIFigure.Name = 'Konverzija formata boja';

            % Create TitleLabel
            app.TitleLabel = uilabel(app.UIFigure);
            app.TitleLabel.FontSize = 22;
            app.TitleLabel.FontWeight = 'bold';
            app.TitleLabel.Position = [24 704 1152 32];
            app.TitleLabel.Text = 'Konverzija formata boja';

            % Create ControlsPanel
            app.ControlsPanel = uipanel(app.UIFigure);
            app.ControlsPanel.Title = 'Konverzija';
            app.ControlsPanel.FontSize = 14;
            app.ControlsPanel.FontWeight = 'bold';
            app.ControlsPanel.Position = [24 24 372 664];

            % Create SectionLabel
            app.SectionLabel = uilabel(app.ControlsPanel);
            app.SectionLabel.FontSize = 13;
            app.SectionLabel.Position = [16 600 340 22];
            app.SectionLabel.Text = 'Odaberi konverziju';

            % Create RGBButton
            app.RGBButton = uibutton(app.ControlsPanel, 'push');
            app.RGBButton.ButtonPushedFcn = createCallbackFcn(app, @RGBButtonPushed, true);
            app.RGBButton.FontSize = 12;
            app.RGBButton.Position = [16 548 160 36];
            app.RGBButton.Text = 'RGB';

            % Create HSLButton
            app.HSLButton = uibutton(app.ControlsPanel, 'push');
            app.HSLButton.ButtonPushedFcn = createCallbackFcn(app, @HSLButtonPushed, true);
            app.HSLButton.FontSize = 12;
            app.HSLButton.Position = [16 500 160 36];
            app.HSLButton.Text = 'HSV';

            % Create CIELabButton
            app.CIELabButton = uibutton(app.ControlsPanel, 'push');
            app.CIELabButton.ButtonPushedFcn = createCallbackFcn(app, @CIELabButtonPushed, true);
            app.CIELabButton.FontSize = 12;
            app.CIELabButton.Position = [16 452 160 36];
            app.CIELabButton.Text = 'CIE Lab';

            % Create YCbCrButton
            app.YCbCrButton = uibutton(app.ControlsPanel, 'push');
            app.YCbCrButton.ButtonPushedFcn = createCallbackFcn(app, @YCbCrButtonPushed, true);
            app.YCbCrButton.FontSize = 12;
            app.YCbCrButton.Position = [16 404 160 36];
            app.YCbCrButton.Text = 'YCbCr';

            % Create PreuzmikonvertovanuslikuButton
            app.PreuzmikonvertovanuslikuButton = uibutton(app.ControlsPanel, 'push');
            app.PreuzmikonvertovanuslikuButton.ButtonPushedFcn = createCallbackFcn(app, @PreuzmikonvertovanuslikuButtonPushed, true);
            app.PreuzmikonvertovanuslikuButton.BackgroundColor = [0.2 0.45 0.75];
            app.PreuzmikonvertovanuslikuButton.WordWrap = 'on';
            app.PreuzmikonvertovanuslikuButton.FontSize = 13;
            app.PreuzmikonvertovanuslikuButton.FontWeight = 'bold';
            app.PreuzmikonvertovanuslikuButton.FontColor = [1 1 1];
            app.PreuzmikonvertovanuslikuButton.Position = [156 16 200 44];
            app.PreuzmikonvertovanuslikuButton.Text = 'Preuzmi konvertovanu sliku';

            % Create OriginalPanel
            app.OriginalPanel = uipanel(app.UIFigure);
            app.OriginalPanel.Title = 'Originalna slika';
            app.OriginalPanel.FontSize = 14;
            app.OriginalPanel.FontWeight = 'bold';
            app.OriginalPanel.Position = [412 364 764 324];

            % Create Original
            app.Original = uiimage(app.OriginalPanel);
            app.Original.Position = [16 12 732 278];

            % Create ConvertedPanel
            app.ConvertedPanel = uipanel(app.UIFigure);
            app.ConvertedPanel.Title = 'Konvertovana slika';
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
        function app = ColorFormatsConversion

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
