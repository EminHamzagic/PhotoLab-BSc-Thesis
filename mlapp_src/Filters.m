classdef Filters < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                      matlab.ui.Figure
        TitleLabel                    matlab.ui.control.Label
        NoisePanel                    matlab.ui.container.Panel
        TipumaLabel                   matlab.ui.control.Label
        NoiseTypeDropDown             matlab.ui.control.DropDown
        OdaberitejainuumaSliderLabel  matlab.ui.control.Label
        OdaberitejainuumaSlider       matlab.ui.control.Slider
        SigmaEditFieldLabel           matlab.ui.control.Label
        SigmaEditField                matlab.ui.control.NumericEditField
        AddNoiseButton                matlab.ui.control.Button
        FilterPanel                   matlab.ui.container.Panel
        AlgoSectionLabel              matlab.ui.control.Label
        FilterGroup                   matlab.ui.container.ButtonGroup
        MedianRadio                   matlab.ui.control.RadioButton
        GaussianRadio                 matlab.ui.control.RadioButton
        BlockMatchingRadio            matlab.ui.control.RadioButton
        BM3DRadio                     matlab.ui.control.RadioButton
        ResultSectionLabel            matlab.ui.control.Label
        NoisyPSNRNameLabel            matlab.ui.control.Label
        NoisyPSNRValueLabel           matlab.ui.control.Label
        PSNRNameLabel                 matlab.ui.control.Label
        PSNRValueLabel                matlab.ui.control.Label
        TimeValueLabel                matlab.ui.control.Label
        ApplyFilterButton             matlab.ui.control.Button
        OriginalPanel                 matlab.ui.container.Panel
        Original                      matlab.ui.control.Image
        NoisyPanel                    matlab.ui.container.Panel
        NoisyImage                    matlab.ui.control.Image
        FilteredPanel                 matlab.ui.container.Panel
        FilteredImage                 matlab.ui.control.Image
    end

    properties (Access = private)
        LoadedImage % Čista slika prosleđena iz Options prozora
        NoisyData % Slika sa šumom (izvor za sve filtere, ne čita se iz ImageSource)
        NoiseType = 'none' % 'none' | 'gaussian' | 'saltpepper'
    end

    methods (Access = public)

        function loadImage(app, image)
            app.LoadedImage = image;
            app.Original.ImageSource = image;
        end
    end

    methods (Access = private)

        % Odlučuje da li se BM3D / Block-Matching smeju pokrenuti i vraća sigmu
        % (skala 0-255). choice je 'run', 'median' ili 'cancel'.
        function [choice, sigma] = resolveSigma(app)
            choice = 'run';
            sigma = app.SigmaEditField.Value;
            if strcmp(app.NoiseType, 'saltpepper')
                answer = uiconfirm(app.UIFigure, ...
                    ['Dodali ste salt & pepper (impulsni) šum. BM3D i Block-Matching ' ...
                     'pretpostavljaju Gaussov šum i neće ga ukloniti. Preporučuje se Median filter.'], ...
                    'Neodgovarajući tip šuma', ...
                    'Options', {'Primeni Median', 'Nastavi svejedno', 'Otkaži'}, ...
                    'DefaultOption', 1, 'CancelOption', 3);
                switch answer
                    case 'Primeni Median'
                        choice = 'median';
                        app.MedianRadio.Value = true;
                        return;
                    case 'Otkaži'
                        choice = 'cancel';
                        return;
                end
            end
            if ~isfinite(sigma) || sigma <= 0
                sigma = estimateNoiseSigma(app.NoisyData);
                app.SigmaEditField.Value = min(sigma, 100);
            end
        end

        % Izvršava odabrani filter nad šumnom slikom i prikazuje rezultat
        function runFilter(app, tag, sigma)
            app.ApplyFilterButton.Enable = 'off';
            dlg = uiprogressdlg(app.UIFigure, 'Title', 'Filtriranje', ...
                'Message', 'Obrada u toku...', 'Indeterminate', 'on');
            tStart = tic;
            try
                noisy = app.NoisyData;
                switch tag
                    case 'median'
                        result = noisy;
                        for c = 1:size(noisy, 3)
                            result(:, :, c) = medfilt2(noisy(:, :, c), [3 3]);
                        end
                    case 'gaussian'
                        result = imgaussfilt(noisy, 2);
                    case 'blockmatching'
                        dlg.Indeterminate = 'off';
                        opts = struct('ProgressFcn', @(f) set(dlg, 'Value', f));
                        result = blockMatchingDenoise(noisy, sigma, opts);
                    case 'bm3d'
                        result = bm3dDenoise(noisy, sigma);
                end
                showResult(app, result, toc(tStart));
            catch err
                uialert(app.UIFigure, err.message, 'Greška');
            end
            close(dlg);
            app.ApplyFilterButton.Enable = 'on';
        end

        % Prikazuje rezultat i PSNR u odnosu na originalnu sliku
        function showResult(app, result, elapsed)
            app.FilteredImage.ImageSource = result;
            app.PSNRValueLabel.Text = sprintf('%.2f dB', psnr(im2double(result), im2double(app.LoadedImage)));
            app.TimeValueLabel.Text = sprintf('Vreme: %.1f s', elapsed);
        end
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            appDir = fileparts(fileparts(which('Filters')));
            if isfolder(fullfile(appDir, 'utils'))
                addpath(fullfile(appDir, 'utils'));
            end
            movegui(app.UIFigure, 'center');
        end

        % Value changed function: OdaberitejainuumaSlider
        function OdaberitejainuumaSliderValueChanged(app, event)
            if strcmp(app.NoiseTypeDropDown.Value, 'Gaussian')
                app.SigmaEditField.Value = app.OdaberitejainuumaSlider.Value * 5;
            end
        end

        % Button pushed function: AddNoiseButton
        function AddNoiseButtonPushed(app, event)
            if isempty(app.LoadedImage)
                uialert(app.UIFigure, 'Morate izabrati sliku prvo!', 'Warning');
                return;
            end
            strength = app.OdaberitejainuumaSlider.Value;
            switch app.NoiseTypeDropDown.Value
                case 'Gaussian'
                    sigma = app.SigmaEditField.Value;
                    app.NoisyData = addGaussianNoise(app.LoadedImage, sigma);
                    app.NoiseType = 'gaussian';
                case 'Salt & Pepper'
                    app.NoisyData = imnoise(app.LoadedImage, 'salt & pepper', strength / 10);
                    app.NoiseType = 'saltpepper';
                    app.SigmaEditField.Value = min(estimateNoiseSigma(app.NoisyData), 100);
            end
            app.NoisyImage.ImageSource = app.NoisyData;
            app.NoisyPSNRValueLabel.Text = sprintf('%.2f dB', psnr(im2double(app.NoisyData), im2double(app.LoadedImage)));
            app.FilteredImage.ImageSource = '';
            app.PSNRValueLabel.Text = '—';
            app.TimeValueLabel.Text = 'Vreme: —';
        end

        % Button pushed function: ApplyFilterButton
        function ApplyFilterButtonPushed(app, event)
            if isempty(app.NoisyData)
                uialert(app.UIFigure, 'Prvo dodajte šum na sliku!', 'Warning');
                return;
            end
            tag = app.FilterGroup.SelectedObject.Tag;
            sigma = 0;
            if any(strcmp(tag, {'blockmatching', 'bm3d'}))
                [choice, sigma] = resolveSigma(app);
                if strcmp(choice, 'cancel')
                    return;
                end
                if strcmp(choice, 'median')
                    tag = 'median';
                end
            end
            runFilter(app, tag, sigma);
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 1200 760];
            app.UIFigure.Name = 'Dodavanje šuma i filteri';

            % Create TitleLabel
            app.TitleLabel = uilabel(app.UIFigure);
            app.TitleLabel.FontSize = 22;
            app.TitleLabel.FontWeight = 'bold';
            app.TitleLabel.Position = [24 704 1152 32];
            app.TitleLabel.Text = 'Dodavanje šuma i filteri';

            % Create NoisePanel
            app.NoisePanel = uipanel(app.UIFigure);
            app.NoisePanel.Title = 'Šum';
            app.NoisePanel.FontSize = 14;
            app.NoisePanel.FontWeight = 'bold';
            app.NoisePanel.Position = [24 472 372 216];

            % Create TipumaLabel
            app.TipumaLabel = uilabel(app.NoisePanel);
            app.TipumaLabel.FontSize = 12;
            app.TipumaLabel.Position = [16 140 110 24];
            app.TipumaLabel.Text = 'Tip šuma:';

            % Create NoiseTypeDropDown
            app.NoiseTypeDropDown = uidropdown(app.NoisePanel);
            app.NoiseTypeDropDown.Items = {'Gaussian', 'Salt & Pepper'};
            app.NoiseTypeDropDown.FontSize = 12;
            app.NoiseTypeDropDown.Position = [130 140 210 24];
            app.NoiseTypeDropDown.Value = 'Gaussian';

            % Create OdaberitejainuumaSliderLabel
            app.OdaberitejainuumaSliderLabel = uilabel(app.NoisePanel);
            app.OdaberitejainuumaSliderLabel.FontSize = 12;
            app.OdaberitejainuumaSliderLabel.Position = [16 104 110 24];
            app.OdaberitejainuumaSliderLabel.Text = 'Jačina šuma:';

            % Create OdaberitejainuumaSlider
            app.OdaberitejainuumaSlider = uislider(app.NoisePanel);
            app.OdaberitejainuumaSlider.Limits = [0 10];
            app.OdaberitejainuumaSlider.MajorTicks = [0 5 10];
            app.OdaberitejainuumaSlider.ValueChangedFcn = createCallbackFcn(app, @OdaberitejainuumaSliderValueChanged, true);
            app.OdaberitejainuumaSlider.FontSize = 12;
            app.OdaberitejainuumaSlider.Position = [140 116 190 3];
            app.OdaberitejainuumaSlider.Value = 5;

            % Create SigmaEditFieldLabel
            app.SigmaEditFieldLabel = uilabel(app.NoisePanel);
            app.SigmaEditFieldLabel.FontSize = 12;
            app.SigmaEditFieldLabel.Position = [16 60 110 24];
            app.SigmaEditFieldLabel.Text = 'σ šuma (0-255):';

            % Create SigmaEditField
            app.SigmaEditField = uieditfield(app.NoisePanel, 'numeric');
            app.SigmaEditField.Limits = [0 100];
            app.SigmaEditField.ValueDisplayFormat = '%.1f';
            app.SigmaEditField.FontSize = 12;
            app.SigmaEditField.Position = [130 60 100 24];
            app.SigmaEditField.Value = 25;

            % Create AddNoiseButton
            app.AddNoiseButton = uibutton(app.NoisePanel, 'push');
            app.AddNoiseButton.ButtonPushedFcn = createCallbackFcn(app, @AddNoiseButtonPushed, true);
            app.AddNoiseButton.FontSize = 12;
            app.AddNoiseButton.Position = [180 12 160 36];
            app.AddNoiseButton.Text = 'Dodaj šum';

            % Create FilterPanel
            app.FilterPanel = uipanel(app.UIFigure);
            app.FilterPanel.Title = 'Filter';
            app.FilterPanel.FontSize = 14;
            app.FilterPanel.FontWeight = 'bold';
            app.FilterPanel.Position = [24 24 372 432];

            % Create AlgoSectionLabel
            app.AlgoSectionLabel = uilabel(app.FilterPanel);
            app.AlgoSectionLabel.FontSize = 13;
            app.AlgoSectionLabel.Position = [16 372 340 22];
            app.AlgoSectionLabel.Text = 'Algoritam';

            % Create FilterGroup
            app.FilterGroup = uibuttongroup(app.FilterPanel);
            app.FilterGroup.BorderType = 'none';
            app.FilterGroup.Position = [16 216 340 148];

            % Create MedianRadio
            app.MedianRadio = uiradiobutton(app.FilterGroup);
            app.MedianRadio.Tag = 'median';
            app.MedianRadio.Text = 'Median filter (3x3)';
            app.MedianRadio.FontSize = 12;
            app.MedianRadio.Position = [8 112 320 24];
            app.MedianRadio.Value = true;

            % Create GaussianRadio
            app.GaussianRadio = uiradiobutton(app.FilterGroup);
            app.GaussianRadio.Tag = 'gaussian';
            app.GaussianRadio.Text = 'Gaussian filter (σ = 2)';
            app.GaussianRadio.FontSize = 12;
            app.GaussianRadio.Position = [8 76 320 24];

            % Create BlockMatchingRadio
            app.BlockMatchingRadio = uiradiobutton(app.FilterGroup);
            app.BlockMatchingRadio.Tag = 'blockmatching';
            app.BlockMatchingRadio.Text = 'Block-Matching algoritam';
            app.BlockMatchingRadio.FontSize = 12;
            app.BlockMatchingRadio.Position = [8 40 320 24];

            % Create BM3DRadio
            app.BM3DRadio = uiradiobutton(app.FilterGroup);
            app.BM3DRadio.Tag = 'bm3d';
            app.BM3DRadio.Text = '3D Filtering (BM3D)';
            app.BM3DRadio.FontSize = 12;
            app.BM3DRadio.Position = [8 4 320 24];

            % Create ResultSectionLabel
            app.ResultSectionLabel = uilabel(app.FilterPanel);
            app.ResultSectionLabel.FontSize = 13;
            app.ResultSectionLabel.Position = [16 176 340 22];
            app.ResultSectionLabel.Text = 'Rezultat';

            % Create NoisyPSNRNameLabel
            app.NoisyPSNRNameLabel = uilabel(app.FilterPanel);
            app.NoisyPSNRNameLabel.FontSize = 12;
            app.NoisyPSNRNameLabel.Position = [16 144 170 24];
            app.NoisyPSNRNameLabel.Text = 'PSNR slike sa šumom:';

            % Create NoisyPSNRValueLabel
            app.NoisyPSNRValueLabel = uilabel(app.FilterPanel);
            app.NoisyPSNRValueLabel.FontSize = 12;
            app.NoisyPSNRValueLabel.FontWeight = 'bold';
            app.NoisyPSNRValueLabel.Position = [190 144 166 24];
            app.NoisyPSNRValueLabel.Text = '—';

            % Create PSNRNameLabel
            app.PSNRNameLabel = uilabel(app.FilterPanel);
            app.PSNRNameLabel.FontSize = 12;
            app.PSNRNameLabel.Position = [16 108 170 24];
            app.PSNRNameLabel.Text = 'PSNR filtrirane slike:';

            % Create PSNRValueLabel
            app.PSNRValueLabel = uilabel(app.FilterPanel);
            app.PSNRValueLabel.FontSize = 20;
            app.PSNRValueLabel.FontWeight = 'bold';
            app.PSNRValueLabel.FontColor = [0.18 0.55 0.34];
            app.PSNRValueLabel.Position = [16 68 200 32];
            app.PSNRValueLabel.Text = '—';

            % Create TimeValueLabel
            app.TimeValueLabel = uilabel(app.FilterPanel);
            app.TimeValueLabel.FontSize = 12;
            app.TimeValueLabel.Position = [230 72 126 24];
            app.TimeValueLabel.Text = 'Vreme: —';

            % Create ApplyFilterButton
            app.ApplyFilterButton = uibutton(app.FilterPanel, 'push');
            app.ApplyFilterButton.ButtonPushedFcn = createCallbackFcn(app, @ApplyFilterButtonPushed, true);
            app.ApplyFilterButton.BackgroundColor = [0.2 0.45 0.75];
            app.ApplyFilterButton.FontSize = 13;
            app.ApplyFilterButton.FontWeight = 'bold';
            app.ApplyFilterButton.FontColor = [1 1 1];
            app.ApplyFilterButton.Position = [156 12 200 44];
            app.ApplyFilterButton.Text = 'Primeni filter';

            % Create OriginalPanel
            app.OriginalPanel = uipanel(app.UIFigure);
            app.OriginalPanel.Title = 'Originalna slika';
            app.OriginalPanel.FontSize = 14;
            app.OriginalPanel.FontWeight = 'bold';
            app.OriginalPanel.Position = [412 364 374 324];

            % Create Original
            app.Original = uiimage(app.OriginalPanel);
            app.Original.Position = [16 12 342 278];

            % Create NoisyPanel
            app.NoisyPanel = uipanel(app.UIFigure);
            app.NoisyPanel.Title = 'Slika sa šumom';
            app.NoisyPanel.FontSize = 14;
            app.NoisyPanel.FontWeight = 'bold';
            app.NoisyPanel.Position = [802 364 374 324];

            % Create NoisyImage
            app.NoisyImage = uiimage(app.NoisyPanel);
            app.NoisyImage.Position = [16 12 342 278];

            % Create FilteredPanel
            app.FilteredPanel = uipanel(app.UIFigure);
            app.FilteredPanel.Title = 'Slika sa primenjenim filterom';
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
        function app = Filters

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
