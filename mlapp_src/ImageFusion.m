classdef ImageFusion < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure               matlab.ui.Figure
        TitleLabel             matlab.ui.control.Label
        ControlsPanel          matlab.ui.container.Panel
        SectionLabel           matlab.ui.control.Label
        UitajprvuslikuButton   matlab.ui.control.Button
        UitajdruguslikuButton  matlab.ui.control.Button
        PreuzmislikuButton     matlab.ui.control.Button
        KombinujslikeButton    matlab.ui.control.Button
        FirstPanel             matlab.ui.container.Panel
        FirstImage             matlab.ui.control.Image
        SecondPanel            matlab.ui.container.Panel
        SecondImage            matlab.ui.control.Image
        FusedPanel             matlab.ui.container.Panel
        FusedImage             matlab.ui.control.Image
    end

    properties (Access = private)
        Image1 % Prva slika
        Image2 % Druga slika
        im1Loaded = false; % Da li je prva slika učitana
        im2Loaded = false; % Da li je druga slika učitana
        DownloadImge; % Kombinovana slika spremna za čuvanje
    end

    methods (Access = public)

        function results = loadImage1(app)
            [filename, pathname] = uigetfile('*.png;*.jpg;*.jpeg', "Izaberi sliku");

            if isequal(filename, 0)
                figure(app.UIFigure);
                return;
            end

            filename = strcat(pathname, filename);
            app.Image1=imread(filename);
            app.FirstImage.ImageSource = app.Image1;
            app.im1Loaded = true;

            figure(app.UIFigure);
        end

        function results = loadImage2(app)
            [filename, pathname] = uigetfile('*.png;*.jpg;*.jpeg', "Izaberi sliku");

            if isequal(filename, 0)
                figure(app.UIFigure);
                return;
            end

            filename = strcat(pathname, filename);
            app.Image2=imread(filename);
            app.SecondImage.ImageSource = app.Image2;
            app.im2Loaded = true;

            figure(app.UIFigure);
        end

        function results = fuseImages(app)
            if isempty(app.Image1) || isempty(app.Image2)
                uialert(app.UIFigure, 'Please load both images before fusing.', 'Error');
                return;
            end

            % Ensure images are RGB
            if size(app.Image1, 3) ~= 3
                uialert(app.UIFigure, 'Image 1 must be a color image.', 'Error');
                return;
            end
            if size(app.Image2, 3) ~= 3
                uialert(app.UIFigure, 'Image 2 must be a color image.', 'Error');
                return;
            end

            % Resize images to the same size
            minRows = min(size(app.Image1, 1), size(app.Image2, 1));
            minCols = min(size(app.Image1, 2), size(app.Image2, 2));

            img1 = im2double(imresize(app.Image1, [minRows, minCols]));
            img2 = im2double(imresize(app.Image2, [minRows, minCols]));

            % Initialize the fused image
            fusedImage = zeros(size(img1));

            % Process each color channel separately
            for channel = 1:3
                % Perform DWT on both images for the current channel
                [cA1, cH1, cV1, cD1] = dwt2(img1(:, :, channel), 'haar');
                [cA2, cH2, cV2, cD2] = dwt2(img2(:, :, channel), 'haar');

                % Fuse coefficients
                fusedCA = min(cA1, cA2) % Average approximation coefficients
                fusedCH = max(cH1, cH2);   % Maximum detail coefficients
                fusedCV = max(cV1, cV2);
                fusedCD = max(cD1, cD2);

                % Perform Inverse DWT
                fusedChannel = idwt2(fusedCA, fusedCH, fusedCV, fusedCD, 'haar');

                % Clamp values to [0, 1]
                fusedChannel = min(max(fusedChannel, 0), 1);

                % Store the fused channel
                fusedImage(:, :, channel) = fusedChannel;
            end

            % Convert the fused image to uint8
            fusedImage = im2uint8(fusedImage);

            % Display the fused image in the Image component
            app.DownloadImge = fusedImage;
            app.FusedImage.ImageSource = fusedImage;
        end
    end

    methods (Access = public)

        function results = DownloadFusedImage(app)
            if isempty(app.DownloadImge)
                uialert(app.UIFigure, 'Ne postoji kombinovana slika za preuzimanje. Kombinujte slike prvo', 'Error');
                return;
            end

            [file, path] = uiputfile({'*.jpg', 'JPEG Image (*.jpg)'; '*.png', 'PNG Image (*.png)'}, 'Save Fused Image');
            if isequal(file, 0)
                return; % User canceled
            end

            % Save the fused image
            imwrite(app.DownloadImge, fullfile(path, file));
            uialert(app.UIFigure, 'Kombinovana slika je uspešno sačuvana!', 'Success');
            figure(app.UIFigure);
        end
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            movegui(app.UIFigure, 'center');
        end

        % Button pushed function: UitajprvuslikuButton
        function UitajprvuslikuButtonPushed(app, event)
            loadImage1(app);
        end

        % Button pushed function: UitajdruguslikuButton
        function UitajdruguslikuButtonPushed(app, event)
            loadImage2(app);
        end

        % Button pushed function: KombinujslikeButton
        function KombinujslikeButtonPushed(app, event)
            fuseImages(app);
        end

        % Button pushed function: PreuzmislikuButton
        function PreuzmislikuButtonPushed(app, event)
            DownloadFusedImage(app);
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 1200 760];
            app.UIFigure.Name = 'Fuzija slika';

            % Create TitleLabel
            app.TitleLabel = uilabel(app.UIFigure);
            app.TitleLabel.FontSize = 22;
            app.TitleLabel.FontWeight = 'bold';
            app.TitleLabel.Position = [24 704 1152 32];
            app.TitleLabel.Text = 'Fuzija slika';

            % Create ControlsPanel
            app.ControlsPanel = uipanel(app.UIFigure);
            app.ControlsPanel.Title = 'Ulazne slike';
            app.ControlsPanel.FontSize = 14;
            app.ControlsPanel.FontWeight = 'bold';
            app.ControlsPanel.Position = [24 24 372 664];

            % Create SectionLabel
            app.SectionLabel = uilabel(app.ControlsPanel);
            app.SectionLabel.FontSize = 13;
            app.SectionLabel.Position = [16 600 340 22];
            app.SectionLabel.Text = 'Učitajte dve slike i kombinujte ih (DWT, Haar)';

            % Create UitajprvuslikuButton
            app.UitajprvuslikuButton = uibutton(app.ControlsPanel, 'push');
            app.UitajprvuslikuButton.ButtonPushedFcn = createCallbackFcn(app, @UitajprvuslikuButtonPushed, true);
            app.UitajprvuslikuButton.FontSize = 12;
            app.UitajprvuslikuButton.Position = [16 548 160 36];
            app.UitajprvuslikuButton.Text = 'Učitaj prvu sliku';

            % Create UitajdruguslikuButton
            app.UitajdruguslikuButton = uibutton(app.ControlsPanel, 'push');
            app.UitajdruguslikuButton.ButtonPushedFcn = createCallbackFcn(app, @UitajdruguslikuButtonPushed, true);
            app.UitajdruguslikuButton.FontSize = 12;
            app.UitajdruguslikuButton.Position = [16 500 160 36];
            app.UitajdruguslikuButton.Text = 'Učitaj drugu sliku';

            % Create PreuzmislikuButton
            app.PreuzmislikuButton = uibutton(app.ControlsPanel, 'push');
            app.PreuzmislikuButton.ButtonPushedFcn = createCallbackFcn(app, @PreuzmislikuButtonPushed, true);
            app.PreuzmislikuButton.FontSize = 12;
            app.PreuzmislikuButton.Position = [16 452 160 36];
            app.PreuzmislikuButton.Text = 'Preuzmi sliku';

            % Create KombinujslikeButton
            app.KombinujslikeButton = uibutton(app.ControlsPanel, 'push');
            app.KombinujslikeButton.ButtonPushedFcn = createCallbackFcn(app, @KombinujslikeButtonPushed, true);
            app.KombinujslikeButton.BackgroundColor = [0.2 0.45 0.75];
            app.KombinujslikeButton.FontSize = 13;
            app.KombinujslikeButton.FontWeight = 'bold';
            app.KombinujslikeButton.FontColor = [1 1 1];
            app.KombinujslikeButton.Position = [156 16 200 44];
            app.KombinujslikeButton.Text = 'Kombinuj slike';

            % Create FirstPanel
            app.FirstPanel = uipanel(app.UIFigure);
            app.FirstPanel.Title = 'Prva slika';
            app.FirstPanel.FontSize = 14;
            app.FirstPanel.FontWeight = 'bold';
            app.FirstPanel.Position = [412 364 374 324];

            % Create FirstImage
            app.FirstImage = uiimage(app.FirstPanel);
            app.FirstImage.Position = [16 12 342 278];

            % Create SecondPanel
            app.SecondPanel = uipanel(app.UIFigure);
            app.SecondPanel.Title = 'Druga slika';
            app.SecondPanel.FontSize = 14;
            app.SecondPanel.FontWeight = 'bold';
            app.SecondPanel.Position = [802 364 374 324];

            % Create SecondImage
            app.SecondImage = uiimage(app.SecondPanel);
            app.SecondImage.Position = [16 12 342 278];

            % Create FusedPanel
            app.FusedPanel = uipanel(app.UIFigure);
            app.FusedPanel.Title = 'Kombinovana slika';
            app.FusedPanel.FontSize = 14;
            app.FusedPanel.FontWeight = 'bold';
            app.FusedPanel.Position = [412 24 764 324];

            % Create FusedImage
            app.FusedImage = uiimage(app.FusedPanel);
            app.FusedImage.Position = [16 12 732 278];

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = ImageFusion

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
