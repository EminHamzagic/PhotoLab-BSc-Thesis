classdef WienerFilter < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure             matlab.ui.Figure
        TitleLabel           matlab.ui.control.Label
        ControlsPanel        matlab.ui.container.Panel
        SectionLabel         matlab.ui.control.Label
        PSFEditFieldLabel    matlab.ui.control.Label
        PSFEditField         matlab.ui.control.EditField
        SNREditField_2Label  matlab.ui.control.Label
        SNREditField         matlab.ui.control.NumericEditField
        PreuzmiSlikuButton   matlab.ui.control.Button
        ApplyFilterButton    matlab.ui.control.Button
        OriginalPanel        matlab.ui.container.Panel
        Original             matlab.ui.control.Image
        FilteredPanel        matlab.ui.container.Panel
        FilteredImage        matlab.ui.control.Image
    end

    properties (Access = private)
        LoadedImage % Slika prosleđena iz Options prozora
        FilteredImageData % Poslednja izračunata filtrirana slika (za preuzimanje)
    end

    methods (Access = public)

        function loadImage(app, image)
            app.LoadedImage = image;
            % uiimage traži RGB, pa 2D sliku prikaži replicirano po 3 kanala
            if ismatrix(image) && size(image, 3) == 1
                app.Original.ImageSource = repmat(image, [1 1 3]);
            else
                app.Original.ImageSource = image;
            end
        end
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            movegui(app.UIFigure, 'center');
        end

        % Button pushed function: ApplyFilterButton
        function ApplyFilterButtonPushed(app, event)
            if isempty(app.LoadedImage)
                uialert(app.UIFigure, 'Morate izabrati sliku prvo!', 'Warning');
                return;
            end

            % Dohvati učitanu sliku
            originalImage = app.LoadedImage;

            % Proveri da li je slika grayscale (ako nije, konvertuj je)
            if size(originalImage, 3) == 3
                grayImage = rgb2gray(originalImage);
            else
                grayImage = originalImage;
            end

            % Prevedi sliku u double opseg [0, 1] pre dekonvolucije
            grayImage = im2double(grayImage);

            % Parsiraj PSF vrednost iz unosa kao tekst
            psfText = app.PSFEditField.Value;  % Tekstualni unos PSF-a
            psfMatrix = str2num(psfText);  % Parsiranje teksta u matricu

            % Proveri da li je PSF ispravno unet
            if isempty(psfMatrix) || ~ismatrix(psfMatrix) || size(psfMatrix, 1) ~= 3 || size(psfMatrix, 2) ~= 3
                uialert(app.UIFigure, 'PSF format nije ispravan. Unesite matricu u formatu: [0 1 0; 1 1 1; 0 1 0]', 'Greška');
                return;
            end

            % Normalizuj PSF da mu suma bude 1 (energija se ne menja)
            psfSum = sum(psfMatrix(:));
            if psfSum <= 0
                uialert(app.UIFigure, 'Suma PSF matrice mora biti pozitivna.', 'Greška');
                return;
            end
            psfMatrix = psfMatrix / psfSum;

            % Prikazivanje PSF matrice u komandnom prozoru radi provere
            disp('PSF Matriza:');
            disp(psfMatrix);

            % Proveri da li je SNR unet
            snrValue = app.SNREditField.Value;  % Unos za SNR
            if isempty(snrValue) || snrValue <= 0
                uialert(app.UIFigure, 'Molimo unesite validan SNR.', 'Greška');
                return;
            end

            % Ublaži ivične artefakte pre dekonvolucije
            grayImage = edgetaper(grayImage, psfMatrix);

            % Primeni dekonvoluciju sa Wiener filterom (deconvwnr očekuje NSR = 1/SNR)
            nsrValue = 1 / snrValue;
            deconvolvedImage = deconvwnr(grayImage, psfMatrix, nsrValue);

            % Prevedi rezultat u uint8 sa odsecanjem (bez razvlačenja kontrasta)
            deconvolvedImage = im2uint8(deconvolvedImage);

            % Proveri da li je slika pravilno generisana
            if all(deconvolvedImage(:) == 0)
                uialert(app.UIFigure, 'Dekonvolucija nije dala validan rezultat. Proverite vrednosti PSF i SNR.', 'Greška');
                return;
            end

            % Prikaz filtrirane slike (uiimage traži 3-kanalnu sliku)
            app.FilteredImage.ImageSource = repmat(deconvolvedImage, [1 1 3]);

            % Sačuvaj rezultat radi kasnijeg preuzimanja
            app.FilteredImageData = deconvolvedImage;
        end

        % Button pushed function: PreuzmiSlikuButton
        function PreuzmiSlikuButtonPushed(app, event)
            if isempty(app.FilteredImageData)
                uialert(app.UIFigure, 'Morate prvo primeniti filter!', 'Warning');
                return;
            end

            [filename, pathname] = uiputfile({'*.png';'*.jpg';'*.tif'}, 'Save Image As');
            if isequal(filename, 0)
                disp('User canceled save.');
            else
                fullFileName = fullfile(pathname, filename);
                imwrite(app.FilteredImageData, fullFileName);
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
            app.UIFigure.Name = 'Wiener filter';

            % Create TitleLabel
            app.TitleLabel = uilabel(app.UIFigure);
            app.TitleLabel.FontSize = 22;
            app.TitleLabel.FontWeight = 'bold';
            app.TitleLabel.Position = [24 704 1152 32];
            app.TitleLabel.Text = 'Wiener filter';

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
            app.SectionLabel.Text = 'Wiener dekonvolucija (deconvwnr)';

            % Create PSFEditFieldLabel
            app.PSFEditFieldLabel = uilabel(app.ControlsPanel);
            app.PSFEditFieldLabel.FontSize = 12;
            app.PSFEditFieldLabel.Position = [16 560 340 24];
            app.PSFEditFieldLabel.Text = 'PSF (matrica 3x3):';

            % Create PSFEditField
            app.PSFEditField = uieditfield(app.ControlsPanel, 'text');
            app.PSFEditField.FontSize = 12;
            app.PSFEditField.Position = [16 524 340 24];
            app.PSFEditField.Value = '0 1 0; 1 1 1; 0 1 0';

            % Create SNREditField_2Label
            app.SNREditField_2Label = uilabel(app.ControlsPanel);
            app.SNREditField_2Label.FontSize = 12;
            app.SNREditField_2Label.Position = [16 476 130 24];
            app.SNREditField_2Label.Text = 'SNR:';

            % Create SNREditField
            app.SNREditField = uieditfield(app.ControlsPanel, 'numeric');
            app.SNREditField.FontSize = 12;
            app.SNREditField.Position = [150 476 100 24];
            app.SNREditField.Value = 100;

            % Create PreuzmiSlikuButton
            app.PreuzmiSlikuButton = uibutton(app.ControlsPanel, 'push');
            app.PreuzmiSlikuButton.ButtonPushedFcn = createCallbackFcn(app, @PreuzmiSlikuButtonPushed, true);
            app.PreuzmiSlikuButton.FontSize = 12;
            app.PreuzmiSlikuButton.Position = [196 72 160 36];
            app.PreuzmiSlikuButton.Text = 'Preuzmi sliku';

            % Create ApplyFilterButton
            app.ApplyFilterButton = uibutton(app.ControlsPanel, 'push');
            app.ApplyFilterButton.ButtonPushedFcn = createCallbackFcn(app, @ApplyFilterButtonPushed, true);
            app.ApplyFilterButton.BackgroundColor = [0.2 0.45 0.75];
            app.ApplyFilterButton.FontSize = 13;
            app.ApplyFilterButton.FontWeight = 'bold';
            app.ApplyFilterButton.FontColor = [1 1 1];
            app.ApplyFilterButton.Position = [156 16 200 44];
            app.ApplyFilterButton.Text = 'Primeni filter';

            % Create OriginalPanel
            app.OriginalPanel = uipanel(app.UIFigure);
            app.OriginalPanel.Title = 'Originalna slika';
            app.OriginalPanel.FontSize = 14;
            app.OriginalPanel.FontWeight = 'bold';
            app.OriginalPanel.Position = [412 364 764 324];

            % Create Original
            app.Original = uiimage(app.OriginalPanel);
            app.Original.Position = [16 12 732 278];

            % Create FilteredPanel
            app.FilteredPanel = uipanel(app.UIFigure);
            app.FilteredPanel.Title = 'Filtrirana slika';
            app.FilteredPanel.FontSize = 14;
            app.FilteredPanel.FontWeight = 'bold';
            app.FilteredPanel.Position = [412 24 764 324];

            % Create FilteredImage
            app.FilteredImage = uiimage(app.FilteredPanel);
            app.FilteredImage.Position = [16 12 732 278];

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = WienerFilter

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
