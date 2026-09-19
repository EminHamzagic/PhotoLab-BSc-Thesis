classdef DatasetManagerApp < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure               matlab.ui.Figure
        TitleLabel             matlab.ui.control.Label
        DatasetLabel           matlab.ui.control.Label
        DatasetDropdown        matlab.ui.control.DropDown
        ResizeLabel            matlab.ui.control.Label
        ResizeDropdown         matlab.ui.control.DropDown
        NormalizationLabel     matlab.ui.control.Label
        NormalizationDropdown  matlab.ui.control.DropDown
        DownloadButton         matlab.ui.control.Button
        DatasetStatsText       matlab.ui.control.TextArea
        SampleImageAxes        matlab.ui.control.UIAxes
        ClassDistributionAxes  matlab.ui.control.UIAxes
    end


    properties (Access = public)
        setDimensions          % [H W C] of the data the network will be trained on
        setNormalization       % 'None' | 'MinMax' | 'Mean-Std'
        choosenDataset         string  % here will be path to downloaded dataset
        ParentApp
    end

    properties (Access = private)
        LastResizeValue = '28x28'  % restored if the Custom dialog is cancelled
        LabelCountCache            % containers.Map: dataset dir -> countEachLabel table
    end

    methods (Access = private)

        function cfg = getDatasetConfig(~, datasetName)
            % Per-dataset settings shared by stats, preview and download
            switch datasetName
                case 'MNIST'
                    cfg = struct('subdir', 'MNIST', 'channels', 1, 'prepareFcn', @prepareMNIST, ...
                        'nativeSize', [28 28], 'numClasses', 10, 'numImages', 70000, ...
                        'sample', 'mnist_sample.png');
                case 'Fashion-MNIST'
                    cfg = struct('subdir', 'FashionMNIST', 'channels', 1, 'prepareFcn', @prepareFashionMNIST, ...
                        'nativeSize', [28 28], 'numClasses', 10, 'numImages', 70000, ...
                        'sample', 'fashion_mnist_sample.png');
                case 'CIFAR-10'
                    cfg = struct('subdir', 'CIFAR10', 'channels', 3, 'prepareFcn', @prepareCIFAR10, ...
                        'nativeSize', [32 32], 'numClasses', 10, 'numImages', 60000, ...
                        'sample', 'cifar10_sample.jpg');
                case 'CIFAR-100'
                    cfg = struct('subdir', 'CIFAR100', 'channels', 3, 'prepareFcn', @prepareCIFAR100, ...
                        'nativeSize', [32 32], 'numClasses', 100, 'numImages', 60000, ...
                        'sample', 'cifar100_sample.jpg');
                otherwise
                    cfg = [];
            end
        end

        function targetSize = getTargetSize(app)
            % Parse 'WxH' from the resize dropdown into [H W]
            dims = sscanf(app.ResizeDropdown.Value, '%dx%d');
            if numel(dims) == 2
                targetSize = [dims(2) dims(1)];
            else
                targetSize = [];
            end
        end

        function datasetDir = getDatasetDir(~, cfg, targetSize)
            % Per-size folder, e.g. datasets/MNIST_28x28
            datasetDir = fullfile(pwd, 'datasets', ...
                sprintf('%s_%dx%d', cfg.subdir, targetSize(2), targetSize(1)));
        end

        function tf = isDatasetReady(~, datasetDir)
            % The manifest is written last, so its presence means the download completed
            tf = isfile(fullfile(datasetDir, 'photolab_dataset.mat'));
        end

        function counts = getLabelCounts(app, datasetDir)
            % Real per-class image counts of the training split (cached per folder)
            if isempty(app.LabelCountCache)
                app.LabelCountCache = containers.Map();
            end
            if isKey(app.LabelCountCache, datasetDir)
                counts = app.LabelCountCache(datasetDir);
                return;
            end
            imds = imageDatastore(fullfile(datasetDir, 'training'), ...
                'IncludeSubfolders', true, 'LabelSource', 'foldernames');
            counts = countEachLabel(imds);
            app.LabelCountCache(datasetDir) = counts;
        end

        function updateDatasetStats(app)
            % Update dataset statistics based on selected dataset
            selectedDataset = app.DatasetDropdown.Value;
            cfg = getDatasetConfig(app, selectedDataset);
            targetSize = getTargetSize(app);
            if isempty(cfg) || isempty(targetSize)
                return;
            end

            datasetDir = getDatasetDir(app, cfg, targetSize);
            counts = [];
            if isDatasetReady(app, datasetDir)
                try
                    counts = getLabelCounts(app, datasetDir);
                catch
                    counts = [];
                end
            end

            if cfg.channels == 1
                channelText = 'grayscale';
            else
                channelText = 'RGB';
            end
            if isempty(counts)
                status = 'nije preuzet';
                numImagesText = sprintf('%d (ukupno, training + testing)', cfg.numImages);
            else
                status = sprintf('preuzet (%s)', datasetDir);
                numImagesText = sprintf('%d (training skup)', sum(counts.Count));
            end

            app.DatasetStatsText.Value = {...
                sprintf('Dataset: %s', selectedDataset), ...
                sprintf('Broj klasa: %d', cfg.numClasses), ...
                sprintf('Broj slika: %s', numImagesText), ...
                sprintf('Originalne dimenzije: %dx%d, %s', cfg.nativeSize(2), cfg.nativeSize(1), channelText), ...
                sprintf('Dimenzije za treniranje: %dx%dx%d', targetSize(2), targetSize(1), cfg.channels), ...
                sprintf('Normalizacija (u ulaznom sloju mreže): %s', app.NormalizationDropdown.Value), ...
                sprintf('Status: %s', status)};

            % Display a sample image
            displaySampleImage(app, cfg);

            % Plot class distribution
            plotClassDistribution(app, counts);
        end

        function displaySampleImage(app, cfg)
            % Display a sample image with the selected resize + normalization applied
            cla(app.SampleImageAxes); % Clear the axes
            try
                img = imread(fullfile('+SampleImages', cfg.sample));
                if cfg.channels == 1 && size(img, 3) == 3
                    img = rgb2gray(img);
                end
                img = applyResizingToImage(app, img);
                img = applyNormalizationToImage(app, img);
                imshow(img, 'Parent', app.SampleImageAxes);
                title(app.SampleImageAxes, sprintf('Primjer slike (%dx%d)', size(img, 2), size(img, 1)));
            catch
                xlim(app.SampleImageAxes, [0 1]);
                ylim(app.SampleImageAxes, [0 1]);
                text(app.SampleImageAxes, 0.5, 0.5, 'Nema dostupnih slika', ...
                    'HorizontalAlignment', 'center', 'FontSize', 12);
            end
        end

        function plotClassDistribution(app, counts)
            % Plot real class distribution as a bar chart
            cla(app.ClassDistributionAxes); % Clear the axes
            if ~isempty(counts)
                bar(app.ClassDistributionAxes, counts.Count, 'FaceColor', [0.20 0.45 0.75]);
                xlabel(app.ClassDistributionAxes, 'Klase');
                ylabel(app.ClassDistributionAxes, 'Broj slika');
                title(app.ClassDistributionAxes, 'Distribucija klasa (training)');
                if height(counts) <= 10
                    labels = regexprep(cellstr(counts.Label), '^\d+_', '');
                    app.ClassDistributionAxes.XTick = 1:height(counts);
                    app.ClassDistributionAxes.XTickLabel = labels;
                    app.ClassDistributionAxes.XTickLabelRotation = 45;
                else
                    app.ClassDistributionAxes.XTickMode = 'auto';
                    app.ClassDistributionAxes.XTickLabelMode = 'auto';
                    app.ClassDistributionAxes.XTickLabelRotation = 0;
                end
            else
                title(app.ClassDistributionAxes, '');
                app.ClassDistributionAxes.XTickMode = 'auto';
                app.ClassDistributionAxes.XTickLabelMode = 'auto';
                app.ClassDistributionAxes.XTickLabelRotation = 0;
                xlim(app.ClassDistributionAxes, [0 1]);
                ylim(app.ClassDistributionAxes, [0 1]);
                text(app.ClassDistributionAxes, 0.5, 0.5, ...
                    {'Distribucija će biti prikazana', 'nakon preuzimanja dataseta'}, ...
                    'HorizontalAlignment', 'center', 'FontSize', 12);
            end
        end

        function downloadDataset(app)
            selectedDataset = app.DatasetDropdown.Value;
            cfg = getDatasetConfig(app, selectedDataset);
            targetSize = getTargetSize(app);
            if isempty(cfg)
                uialert(app.UIFigure, 'Dataset nije podržan.', 'Warning');
                return;
            end
            if isempty(targetSize)
                uialert(app.UIFigure, 'Morate izabrati veličinu slike prvo!', 'Warning');
                return;
            end

            baseDatasetDir = fullfile(pwd, 'datasets');
            if ~exist(baseDatasetDir, 'dir')
                mkdir(baseDatasetDir);
            end
            datasetDir = getDatasetDir(app, cfg, targetSize);

            % Already downloaded at this size -> just select it
            if isDatasetReady(app, datasetDir)
                disp('Dataset već postoji. Preskačem preuzimanje.');
                selectDataset(app, datasetDir, targetSize, cfg);
                return;
            end

            % Leftover from an interrupted download
            if exist(datasetDir, 'dir')
                rmdir(datasetDir, 's');
            end
            mkdir(datasetDir);

            % Native resolution is written as-is, anything else is resized while writing
            if isequal(targetSize, cfg.nativeSize)
                prepareSize = [];
            else
                prepareSize = targetSize;
            end

            app.DownloadButton.Enable = 'off';
            h = waitbar(0, sprintf('Preuzimanje %s...', selectedDataset), 'Name', 'Preuzimanje dataseta');
            try
                cfg.prepareFcn(datasetDir, h, prepareSize);
                waitbar(1, h, 'Preuzimanje završeno!');
                pause(1);
                close(h);
                app.DownloadButton.Enable = 'on';
                fprintf('%s dataset uspješno preuzet i pripremljen: %s\n', selectedDataset, datasetDir);
                selectDataset(app, datasetDir, targetSize, cfg);
            catch ME
                if isvalid(h), close(h); end
                app.DownloadButton.Enable = 'on';
                if exist(datasetDir, 'dir')
                    rmdir(datasetDir, 's'); % cleanup
                end
                uialert(app.UIFigure, sprintf('Greška tokom preuzimanja %s:\n%s', selectedDataset, ME.message), 'Greška');
            end
        end

        function selectDataset(app, datasetDir, targetSize, cfg)
            % Publish the result to the parent and release its uiwait
            app.choosenDataset = datasetDir;
            app.setDimensions = [targetSize cfg.channels];
            app.setNormalization = app.NormalizationDropdown.Value;
            uiresume(app.UIFigure);
        end

        function img = applyNormalizationToImage(app, img)
            % Preview of the normalization the network input layer will apply.
            % Mean-Std output is rescaled to [0,1] only so it can be displayed.
            switch app.NormalizationDropdown.Value
                case 'MinMax'
                    img = rescale(double(img));
                case 'Mean-Std'
                    img = double(img);
                    img = (img - mean(img(:))) / std(img(:));
                    img = rescale(img);
            end
        end

        function img = applyResizingToImage(app, img)
            % Apply the selected resize option to the image
            targetSize = getTargetSize(app);
            if ~isempty(targetSize)
                img = imresize(img, targetSize);
            end
        end

        function promptCustomSize(app)
            % Ask for W x H and add it to the dropdown as a regular 'WxH' entry
            answer = inputdlg({'Širina (px):', 'Visina (px):'}, 'Prilagođena veličina', [1 35]);
            if isempty(answer)
                app.ResizeDropdown.Value = app.LastResizeValue;
                return;
            end
            width = round(str2double(answer{1}));
            height = round(str2double(answer{2}));
            if isnan(width) || isnan(height) || width < 8 || height < 8 || width > 1024 || height > 1024
                uialert(app.UIFigure, 'Širina i visina moraju biti cijeli brojevi između 8 i 1024.', 'Warning');
                app.ResizeDropdown.Value = app.LastResizeValue;
                return;
            end
            entry = sprintf('%dx%d', width, height);
            items = app.ResizeDropdown.Items;
            if ~any(strcmp(items, entry))
                app.ResizeDropdown.Items = [items(1:end-1), {entry}, items(end)];
            end
            app.ResizeDropdown.Value = entry;
        end
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            movegui(app.UIFigure, 'center');
            % Initialize dataset statistics
            updateDatasetStats(app);
        end

        % Value changed function: DatasetDropdown
        function DatasetDropdownValueChanged(app, event)
            updateDatasetStats(app);
        end

        % Button pushed function: DownloadButton
        function DownloadButtonPushed(app, event)
            downloadDataset(app);
        end

        % Value changed function: ResizeDropdown
        function ResizeDropdownValueChanged(app, event)
            if strcmp(app.ResizeDropdown.Value, 'Custom')
                promptCustomSize(app);
            end
            app.LastResizeValue = app.ResizeDropdown.Value;
            updateDatasetStats(app);
        end

        % Value changed function: NormalizationDropdown
        function NormalizationDropdownValueChanged(app, event)
            updateDatasetStats(app);
        end

        % Close request function: UIFigure
        function UIFigureCloseRequest(app, event)
            delete(app.UIFigure);
            %delete(app);
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 900 620];
            app.UIFigure.Name = 'Dataset Manager';
            app.UIFigure.CloseRequestFcn = createCallbackFcn(app, @UIFigureCloseRequest, true);

            % Create TitleLabel
            app.TitleLabel = uilabel(app.UIFigure);
            app.TitleLabel.FontSize = 22;
            app.TitleLabel.FontWeight = 'bold';
            app.TitleLabel.Position = [24 564 600 32];
            app.TitleLabel.Text = 'Odabir i priprema dataseta';

            % Create DatasetLabel
            app.DatasetLabel = uilabel(app.UIFigure);
            app.DatasetLabel.FontSize = 13;
            app.DatasetLabel.Position = [24 526 180 22];
            app.DatasetLabel.Text = 'Dataset';

            % Create DatasetDropdown
            app.DatasetDropdown = uidropdown(app.UIFigure);
            app.DatasetDropdown.Items = {'MNIST', 'Fashion-MNIST', 'CIFAR-10', 'CIFAR-100'};
            app.DatasetDropdown.ValueChangedFcn = createCallbackFcn(app, @DatasetDropdownValueChanged, true);
            app.DatasetDropdown.FontSize = 12;
            app.DatasetDropdown.Position = [24 498 180 24];
            app.DatasetDropdown.Value = 'MNIST';

            % Create ResizeLabel
            app.ResizeLabel = uilabel(app.UIFigure);
            app.ResizeLabel.FontSize = 13;
            app.ResizeLabel.Position = [220 526 150 22];
            app.ResizeLabel.Text = 'Veličina slike';

            % Create ResizeDropdown
            app.ResizeDropdown = uidropdown(app.UIFigure);
            app.ResizeDropdown.Items = {'28x28', '32x32', '64x64', '224x224', 'Custom'};
            app.ResizeDropdown.ValueChangedFcn = createCallbackFcn(app, @ResizeDropdownValueChanged, true);
            app.ResizeDropdown.FontSize = 12;
            app.ResizeDropdown.Position = [220 498 150 24];
            app.ResizeDropdown.Value = '28x28';

            % Create NormalizationLabel
            app.NormalizationLabel = uilabel(app.UIFigure);
            app.NormalizationLabel.FontSize = 13;
            app.NormalizationLabel.Position = [386 526 170 22];
            app.NormalizationLabel.Text = 'Normalizacija';

            % Create NormalizationDropdown
            app.NormalizationDropdown = uidropdown(app.UIFigure);
            app.NormalizationDropdown.Items = {'None', 'MinMax', 'Mean-Std'};
            app.NormalizationDropdown.ValueChangedFcn = createCallbackFcn(app, @NormalizationDropdownValueChanged, true);
            app.NormalizationDropdown.FontSize = 12;
            app.NormalizationDropdown.Position = [386 498 170 24];
            app.NormalizationDropdown.Value = 'MinMax';

            % Create DownloadButton
            app.DownloadButton = uibutton(app.UIFigure, 'push');
            app.DownloadButton.ButtonPushedFcn = createCallbackFcn(app, @DownloadButtonPushed, true);
            app.DownloadButton.BackgroundColor = [0.20 0.45 0.75];
            app.DownloadButton.FontColor = [1 1 1];
            app.DownloadButton.FontSize = 13;
            app.DownloadButton.FontWeight = 'bold';
            app.DownloadButton.Position = [676 488 200 44];
            app.DownloadButton.Text = 'Preuzmi i izaberi';

            % Create DatasetStatsText
            app.DatasetStatsText = uitextarea(app.UIFigure);
            app.DatasetStatsText.Editable = 'off';
            app.DatasetStatsText.FontSize = 12;
            app.DatasetStatsText.BackgroundColor = [0.96 0.96 0.96];
            app.DatasetStatsText.Position = [24 340 852 132];

            % Create SampleImageAxes
            app.SampleImageAxes = uiaxes(app.UIFigure);
            app.SampleImageAxes.FontSize = 12;
            app.SampleImageAxes.Position = [24 24 418 300];

            % Create ClassDistributionAxes
            app.ClassDistributionAxes = uiaxes(app.UIFigure);
            app.ClassDistributionAxes.FontSize = 12;
            app.ClassDistributionAxes.Position = [458 24 418 300];

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = DatasetManagerApp

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
