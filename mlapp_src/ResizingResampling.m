classdef ResizingResampling < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                          matlab.ui.Figure
        TitleLabel                        matlab.ui.control.Label
        ControlsPanel                     matlab.ui.container.Panel
        MethodSectionLabel                matlab.ui.control.Label
        InterpolationMethodDropDownLabel  matlab.ui.control.Label
        DropDown                          matlab.ui.control.DropDown
        SizeSectionLabel                  matlab.ui.control.Label
        NewWidthEditFieldLabel            matlab.ui.control.Label
        NewWidthEditField                 matlab.ui.control.NumericEditField
        NewHeightEditFieldLabel           matlab.ui.control.Label
        NewHeightEditField                matlab.ui.control.NumericEditField
        ScaleFactorEditFieldLabel         matlab.ui.control.Label
        ScaleFactorEditField              matlab.ui.control.NumericEditField
        ResultSectionLabel                matlab.ui.control.Label
        SizeValueLabel                    matlab.ui.control.Label
        PreuzmipromenjenuslikuButton      matlab.ui.control.Button
        ApplyResizeButton                 matlab.ui.control.Button
        OriginalPanel                     matlab.ui.container.Panel
        Original                          matlab.ui.control.Image
        ResizedPanel                      matlab.ui.container.Panel
        Resized                           matlab.ui.control.Image
    end

    properties (Access = private)
        LoadedImage % Slika prosleđena iz Options prozora
    end

    methods (Access = public)

        function loadImage(app, image)
            app.LoadedImage = image;
            app.Original.ImageSource = image;
            app.NewWidthEditField.Value = size(image, 2);
            app.NewHeightEditField.Value = size(image, 1);
        end
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            movegui(app.UIFigure, 'center');
        end

        % Button pushed function: ApplyResizeButton
        function ApplyResizeButtonPushed(app, event)
            if isempty(app.LoadedImage)
                uialert(app.UIFigure, 'Morate izabrati sliku prvo!', 'Warning');
                return;
            end
            originalImage = app.LoadedImage;

            % Preuzimanje unetih dimenzija od strane korisnika
            width = app.NewWidthEditField.Value;  % Preuzimanje širine
            height = app.NewHeightEditField.Value; % Preuzimanje visine
            scaleFactor = app.ScaleFactorEditField.Value; % Preuzimanje faktora skaliranja
            method = app.DropDown.Value;  % Odabrana metoda interpolacije
            if isempty(method) || ~ismember(method, {'nearest', 'bilinear', 'bicubic'})
                method = 'bilinear';  % Ako je metoda prazna ili nije validna, postavi na 'bilinear'
            end
            if scaleFactor ~= 1
                newHeight = round(size(originalImage, 1) * scaleFactor);
                newWidth = round(size(originalImage, 2) * scaleFactor);
            else
                newHeight = height;
                newWidth = width;
            end
            if mod(newHeight, 2) ~= 0
                newHeight = newHeight + 1;
            end
            if mod(newWidth, 2) ~= 0
                newWidth = newWidth + 1;
            end
            if newWidth <= 0 || newHeight <= 0
                uialert(app.UIFigure, 'Nevažeće dimenzije, proverite unete vrednosti!', 'Greška');
                return;
            end
            try
                resizedImage = imresize(originalImage, [newHeight newWidth], method);
            catch ME
                uialert(app.UIFigure, ['Greška: ', ME.message], 'Greška');
                return;
            end
            app.Resized.ImageSource = resizedImage;
            app.SizeValueLabel.Text = sprintf('%d x %d', newWidth, newHeight);
        end

        % Button pushed function: PreuzmipromenjenuslikuButton
        function PreuzmipromenjenuslikuButtonPushed(app, event)
            if isempty(app.Resized.ImageSource) || ~isnumeric(app.Resized.ImageSource)
                uialert(app.UIFigure, 'Morate prvo primeniti promenu veličine!', 'Warning');
                return;
            end

            [filename, pathname] = uiputfile({'*.png';'*.jpg';'*.tif'}, 'Save Image As');
            if isequal(filename, 0)
                disp('User canceled save.');
            else
                fullFileName = fullfile(pathname, filename);
                imwrite(im2uint8(app.Resized.ImageSource), fullFileName);
                disp(['Image saved to ', fullFileName]);
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
            app.UIFigure.Name = 'Promena veličine i ponovno uzorkovanje';

            % Create TitleLabel
            app.TitleLabel = uilabel(app.UIFigure);
            app.TitleLabel.FontSize = 22;
            app.TitleLabel.FontWeight = 'bold';
            app.TitleLabel.Position = [24 704 1152 32];
            app.TitleLabel.Text = 'Promena veličine i ponovno uzorkovanje';

            % Create ControlsPanel
            app.ControlsPanel = uipanel(app.UIFigure);
            app.ControlsPanel.Title = 'Parametri';
            app.ControlsPanel.FontSize = 14;
            app.ControlsPanel.FontWeight = 'bold';
            app.ControlsPanel.Position = [24 24 372 664];

            % Create MethodSectionLabel
            app.MethodSectionLabel = uilabel(app.ControlsPanel);
            app.MethodSectionLabel.FontSize = 13;
            app.MethodSectionLabel.Position = [16 600 340 22];
            app.MethodSectionLabel.Text = 'Interpolacija';

            % Create InterpolationMethodDropDownLabel
            app.InterpolationMethodDropDownLabel = uilabel(app.ControlsPanel);
            app.InterpolationMethodDropDownLabel.FontSize = 12;
            app.InterpolationMethodDropDownLabel.Position = [16 560 130 24];
            app.InterpolationMethodDropDownLabel.Text = 'Metoda:';

            % Create DropDown
            app.DropDown = uidropdown(app.ControlsPanel);
            app.DropDown.Items = {'bilinear', 'bicubic', 'nearest'};
            app.DropDown.FontSize = 12;
            app.DropDown.Position = [150 560 190 24];
            app.DropDown.Value = 'bilinear';

            % Create SizeSectionLabel
            app.SizeSectionLabel = uilabel(app.ControlsPanel);
            app.SizeSectionLabel.FontSize = 13;
            app.SizeSectionLabel.Position = [16 500 340 22];
            app.SizeSectionLabel.Text = 'Nove dimenzije';

            % Create NewWidthEditFieldLabel
            app.NewWidthEditFieldLabel = uilabel(app.ControlsPanel);
            app.NewWidthEditFieldLabel.FontSize = 12;
            app.NewWidthEditFieldLabel.Position = [16 460 130 24];
            app.NewWidthEditFieldLabel.Text = 'Širina (px):';

            % Create NewWidthEditField
            app.NewWidthEditField = uieditfield(app.ControlsPanel, 'numeric');
            app.NewWidthEditField.FontSize = 12;
            app.NewWidthEditField.Position = [150 460 100 24];

            % Create NewHeightEditFieldLabel
            app.NewHeightEditFieldLabel = uilabel(app.ControlsPanel);
            app.NewHeightEditFieldLabel.FontSize = 12;
            app.NewHeightEditFieldLabel.Position = [16 424 130 24];
            app.NewHeightEditFieldLabel.Text = 'Visina (px):';

            % Create NewHeightEditField
            app.NewHeightEditField = uieditfield(app.ControlsPanel, 'numeric');
            app.NewHeightEditField.FontSize = 12;
            app.NewHeightEditField.Position = [150 424 100 24];

            % Create ScaleFactorEditFieldLabel
            app.ScaleFactorEditFieldLabel = uilabel(app.ControlsPanel);
            app.ScaleFactorEditFieldLabel.FontSize = 12;
            app.ScaleFactorEditFieldLabel.Position = [16 388 130 24];
            app.ScaleFactorEditFieldLabel.Text = 'Faktor skaliranja:';

            % Create ScaleFactorEditField
            app.ScaleFactorEditField = uieditfield(app.ControlsPanel, 'numeric');
            app.ScaleFactorEditField.FontSize = 12;
            app.ScaleFactorEditField.Position = [150 388 100 24];
            app.ScaleFactorEditField.Value = 1;

            % Create ResultSectionLabel
            app.ResultSectionLabel = uilabel(app.ControlsPanel);
            app.ResultSectionLabel.FontSize = 13;
            app.ResultSectionLabel.Position = [16 328 340 22];
            app.ResultSectionLabel.Text = 'Rezultat (širina x visina)';

            % Create SizeValueLabel
            app.SizeValueLabel = uilabel(app.ControlsPanel);
            app.SizeValueLabel.FontSize = 20;
            app.SizeValueLabel.FontWeight = 'bold';
            app.SizeValueLabel.FontColor = [0.18 0.55 0.34];
            app.SizeValueLabel.Position = [16 288 340 32];
            app.SizeValueLabel.Text = '—';

            % Create PreuzmipromenjenuslikuButton
            app.PreuzmipromenjenuslikuButton = uibutton(app.ControlsPanel, 'push');
            app.PreuzmipromenjenuslikuButton.ButtonPushedFcn = createCallbackFcn(app, @PreuzmipromenjenuslikuButtonPushed, true);
            app.PreuzmipromenjenuslikuButton.FontSize = 12;
            app.PreuzmipromenjenuslikuButton.Position = [196 72 160 36];
            app.PreuzmipromenjenuslikuButton.Text = 'Preuzmi sliku';

            % Create ApplyResizeButton
            app.ApplyResizeButton = uibutton(app.ControlsPanel, 'push');
            app.ApplyResizeButton.ButtonPushedFcn = createCallbackFcn(app, @ApplyResizeButtonPushed, true);
            app.ApplyResizeButton.BackgroundColor = [0.2 0.45 0.75];
            app.ApplyResizeButton.FontSize = 13;
            app.ApplyResizeButton.FontWeight = 'bold';
            app.ApplyResizeButton.FontColor = [1 1 1];
            app.ApplyResizeButton.Position = [156 16 200 44];
            app.ApplyResizeButton.Text = 'Primeni promenu';

            % Create OriginalPanel
            app.OriginalPanel = uipanel(app.UIFigure);
            app.OriginalPanel.Title = 'Originalna slika';
            app.OriginalPanel.FontSize = 14;
            app.OriginalPanel.FontWeight = 'bold';
            app.OriginalPanel.Position = [412 364 764 324];

            % Create Original
            app.Original = uiimage(app.OriginalPanel);
            app.Original.Position = [16 12 732 278];

            % Create ResizedPanel
            app.ResizedPanel = uipanel(app.UIFigure);
            app.ResizedPanel.Title = 'Promenjena slika';
            app.ResizedPanel.FontSize = 14;
            app.ResizedPanel.FontWeight = 'bold';
            app.ResizedPanel.Position = [412 24 764 324];

            % Create Resized
            app.Resized = uiimage(app.ResizedPanel);
            app.Resized.Position = [16 12 732 278];

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = ResizingResampling

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
