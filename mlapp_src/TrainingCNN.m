classdef TrainingCNN < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                    matlab.ui.Figure
        TitleLabel                  matlab.ui.control.Label
        ConfigPanel                 matlab.ui.container.Panel
        ArchNameLabel               matlab.ui.control.Label
        ArchValueLabel              matlab.ui.control.Label
        DatasetNameLabel            matlab.ui.control.Label
        DatasetValueLabel           matlab.ui.control.Label
        InputNameLabel              matlab.ui.control.Label
        InputValueLabel             matlab.ui.control.Label
        NormNameLabel               matlab.ui.control.Label
        NormValueLabel              matlab.ui.control.Label
        HardwarePanel               matlab.ui.container.Panel
        UseGPUCheckBox              matlab.ui.control.CheckBox
        GPUInfoLabel                matlab.ui.control.Label
        TrainingParamsPanel         matlab.ui.container.Panel
        LearningRateLabel           matlab.ui.control.Label
        LearningRateEditField       matlab.ui.control.NumericEditField
        BatchSizeLabel              matlab.ui.control.Label
        BatchSizeEditField          matlab.ui.control.NumericEditField
        EpochsLabel                 matlab.ui.control.Label
        EpochsSpinner               matlab.ui.control.Spinner
        WeightDecayLabel            matlab.ui.control.Label
        WeightDecayEditField        matlab.ui.control.NumericEditField
        OptimizerLabel              matlab.ui.control.Label
        OptimizerDropDown           matlab.ui.control.DropDown
        MomentumLabel               matlab.ui.control.Label
        MomentumEditField           matlab.ui.control.NumericEditField
        Beta1Label                  matlab.ui.control.Label
        Beta1EditField              matlab.ui.control.NumericEditField
        Beta2Label                  matlab.ui.control.Label
        Beta2EditField              matlab.ui.control.NumericEditField
        RMSDecayLabel               matlab.ui.control.Label
        RMSDecayEditField           matlab.ui.control.NumericEditField
        EpsilonLabel                matlab.ui.control.Label
        EpsilonEditField            matlab.ui.control.NumericEditField
        ValidationPanel             matlab.ui.container.Panel
        ValidationSplitLabel        matlab.ui.control.Label
        ValidationSplitSpinner      matlab.ui.control.Spinner
        ValidationFrequencyLabel    matlab.ui.control.Label
        ValidationFrequencySpinner  matlab.ui.control.Spinner
        ValidationPatienceLabel     matlab.ui.control.Label
        ValidationPatienceSpinner   matlab.ui.control.Spinner
        GradientThresholdLabel      matlab.ui.control.Label
        GradientThresholdEditField  matlab.ui.control.NumericEditField
        ShuffleLabel                matlab.ui.control.Label
        ShuffleDropDown             matlab.ui.control.DropDown
        PlotsLabel                  matlab.ui.control.Label
        PlotsDropDown               matlab.ui.control.DropDown
        AugmentationCheckBox        matlab.ui.control.CheckBox
        AugmentationHintLabel       matlab.ui.control.Label
        ResultsPanel                matlab.ui.container.Panel
        StatusLabel                 matlab.ui.control.Label
        TestingAccuracyLabel        matlab.ui.control.Label
        AccuracyLabel               matlab.ui.control.Label
        ValidationAccuracyLabel     matlab.ui.control.Label
        ValAccuracyValueLabel       matlab.ui.control.Label
        TrainingTimeLabel           matlab.ui.control.Label
        TrainingTimeValueLabel      matlab.ui.control.Label
        SavedModelLabel             matlab.ui.control.Label
        SavedModelPathLabel         matlab.ui.control.Label
        StartTrainingButton         matlab.ui.control.Button
    end

    properties (Access = private)
        DatasetPath
        Architecture
        InputDimensions
        Normalization = 'None'
        GPUAvailable = false
    end

    methods (Access = public)
        function loadData(app, architecture, dataset, dimensions, normalization)
            if nargin < 5 || isempty(normalization)
                normalization = 'None';
            end
            app.Architecture = char(architecture);
            app.DatasetPath = char(dataset);
            app.InputDimensions = dimensions;
            app.Normalization = char(normalization);

            [~, datasetName] = fileparts(app.DatasetPath);
            app.ArchValueLabel.Text = app.Architecture;
            app.DatasetValueLabel.Text = datasetName;

            app.InputValueLabel.Text = strjoin(string(dimensions), 'x');
            app.NormValueLabel.Text = app.Normalization;
        end
    end

    methods (Access = private)

        function layerNorm = getInputNormalization(~, normalization)
            % Map the DatasetManagerApp choice to imageInputLayer 'Normalization'
            switch normalization
                case 'MinMax'
                    layerNorm = 'rescale-zero-one';
                case 'Mean-Std'
                    layerNorm = 'zscore';
                otherwise
                    layerNorm = 'none';
            end
        end

        function [layers, netInputSize, normalization] = getLayers(app, archName, inputSize, numClasses, normalization)
            % Returns the layers, the input size the network needs (the datastore
            % is reconciled to it) and the normalization actually applied.
            inputNorm = getInputNormalization(app, normalization);
            switch archName
                case "LeNet"
                    netInputSize = inputSize;
                    layers = [
                        imageInputLayer(inputSize, 'Normalization', inputNorm)

                        convolution2dLayer(5, 6, 'Padding', 'same')
                        batchNormalizationLayer
                        reluLayer
                        averagePooling2dLayer(2, 'Stride', 2)

                        convolution2dLayer(5, 16, 'Padding', 'same')
                        batchNormalizationLayer
                        reluLayer
                        averagePooling2dLayer(2, 'Stride', 2)

                        fullyConnectedLayer(120)
                        reluLayer
                        fullyConnectedLayer(84)
                        reluLayer
                        fullyConnectedLayer(numClasses)
                        softmaxLayer
                        classificationLayer];

                case "AlexNet"
                    % AlexNet scaled for 28x28 / 32x32 inputs: 5 conv + 3 FC.
                    % For larger inputs the first conv strides so the feature
                    % maps reaching the FC layers stay CIFAR-sized.
                    netInputSize = inputSize;
                    stemStride = max(1, round(inputSize(1) / 32));
                    layers = [
                        imageInputLayer(inputSize, 'Normalization', inputNorm, 'Name', 'input')

                        convolution2dLayer(5, 64, 'Stride', stemStride, 'Padding', 'same', 'Name', 'conv1')
                        batchNormalizationLayer('Name', 'bn1')
                        reluLayer('Name', 'relu1')
                        maxPooling2dLayer(2, 'Stride', 2, 'Name', 'pool1')

                        convolution2dLayer(5, 192, 'Padding', 'same', 'Name', 'conv2')
                        batchNormalizationLayer('Name', 'bn2')
                        reluLayer('Name', 'relu2')
                        maxPooling2dLayer(2, 'Stride', 2, 'Name', 'pool2')

                        convolution2dLayer(3, 384, 'Padding', 'same', 'Name', 'conv3')
                        batchNormalizationLayer('Name', 'bn3')
                        reluLayer('Name', 'relu3')
                        convolution2dLayer(3, 256, 'Padding', 'same', 'Name', 'conv4')
                        batchNormalizationLayer('Name', 'bn4')
                        reluLayer('Name', 'relu4')
                        convolution2dLayer(3, 256, 'Padding', 'same', 'Name', 'conv5')
                        batchNormalizationLayer('Name', 'bn5')
                        reluLayer('Name', 'relu5')
                        maxPooling2dLayer(2, 'Stride', 2, 'Name', 'pool5')

                        fullyConnectedLayer(1024, 'Name', 'fc6')
                        reluLayer('Name', 'relu6')
                        dropoutLayer(0.5, 'Name', 'drop6')
                        fullyConnectedLayer(512, 'Name', 'fc7')
                        reluLayer('Name', 'relu7')
                        dropoutLayer(0.5, 'Name', 'drop7')
                        fullyConnectedLayer(numClasses, 'Name', 'fc8')
                        softmaxLayer('Name', 'softmax')
                        classificationLayer('Name', 'output')];

                otherwise
                    error('PhotoLab:unknownArchitecture', 'Arhitektura "%s" nije podržana.', archName);
            end
        end

        function options = getTrainingOptions(~, p, validationData)
            common = {
                'InitialLearnRate', p.lr, ...
                'MaxEpochs', p.epochs, ...
                'MiniBatchSize', p.batchSize, ...
                'L2Regularization', p.weightDecay, ...
                'GradientThreshold', p.gradientThreshold, ...
                'Shuffle', p.shuffle, ...
                'Verbose', false, ...
                'Plots', p.plots, ...
                'ExecutionEnvironment', p.executionEnvironment};
            if ~isempty(validationData)
                common = [common, {
                    'ValidationData', validationData, ...
                    'ValidationFrequency', p.validationFrequency, ...
                    'ValidationPatience', p.validationPatience}];
            end

            switch p.optimizer
                case 'sgdm'
                    options = trainingOptions('sgdm', common{:}, ...
                        'Momentum', p.momentum);
                case 'adam'
                    options = trainingOptions('adam', common{:}, ...
                        'GradientDecayFactor', p.beta1, ...
                        'SquaredGradientDecayFactor', p.beta2, ...
                        'Epsilon', p.epsilon);
                case 'rmsprop'
                    options = trainingOptions('rmsprop', common{:}, ...
                        'SquaredGradientDecayFactor', p.rmsDecay, ...
                        'Epsilon', p.epsilon);
                otherwise
                    error('Unsupported optimizer: %s', p.optimizer);
            end
        end

        function p = collectParams(app)
            % Read every training control into one struct
            p.lr = app.LearningRateEditField.Value;
            p.batchSize = app.BatchSizeEditField.Value;
            p.epochs = app.EpochsSpinner.Value;
            p.weightDecay = app.WeightDecayEditField.Value;
            p.optimizer = app.OptimizerDropDown.Value;
            p.momentum = app.MomentumEditField.Value;
            p.beta1 = app.Beta1EditField.Value;
            p.beta2 = app.Beta2EditField.Value;
            p.rmsDecay = app.RMSDecayEditField.Value;
            p.epsilon = app.EpsilonEditField.Value;
            p.validationFraction = app.ValidationSplitSpinner.Value / 100;
            p.validationFrequency = app.ValidationFrequencySpinner.Value;
            p.validationPatience = app.ValidationPatienceSpinner.Value;
            if p.validationPatience == 0
                p.validationPatience = Inf; % 0 = no early stopping
            end
            p.gradientThreshold = app.GradientThresholdEditField.Value;
            if p.gradientThreshold == 0
                p.gradientThreshold = Inf; % 0 = no gradient clipping
            end
            p.shuffle = app.ShuffleDropDown.Value;
            p.plots = app.PlotsDropDown.Value;
            p.augment = app.AugmentationCheckBox.Value;
            if app.GPUAvailable && app.UseGPUCheckBox.Value
                p.executionEnvironment = 'gpu';
            else
                p.executionEnvironment = 'cpu';
            end
        end

        function probeGPU(app)
            % Enable the GPU option only when trainNetwork can actually use a CUDA GPU
            app.UseGPUCheckBox.Value = false;
            app.UseGPUCheckBox.Enable = 'off';

            hasPCT = license('test', 'Distrib_Computing_Toolbox') && ~isempty(ver('parallel'));
            if ~hasPCT
                app.GPUInfoLabel.Text = ['GPU nije dostupan: Parallel Computing Toolbox nije instaliran ' ...
                    'ili licenciran. Treniranje se izvršava na CPU.'];
                return;
            end

            try
                numGPUs = gpuDeviceCount("available");
            catch
                numGPUs = 0;
            end
            if numGPUs == 0
                app.GPUInfoLabel.Text = ['Nije pronađen podržan NVIDIA GPU (CUDA, compute capability >= 5.0). ' ...
                    'AMD, Intel i Apple GPU nisu podržani. Treniranje se izvršava na CPU.'];
                return;
            end

            if ~canUseGPU()
                app.GPUInfoLabel.Text = ['GPU je pronađen, ali ga MATLAB ne može koristiti ' ...
                    '(provjerite NVIDIA driver). Treniranje se izvršava na CPU.'];
                return;
            end

            try
                gpu = gpuDevice();
                app.GPUInfoLabel.Text = sprintf('%s\nCompute capability: %s\nMemorija: %.1f GB', ...
                    gpu.Name, gpu.ComputeCapability, gpu.TotalMemory / 1e9);
                app.GPUAvailable = true;
                app.UseGPUCheckBox.Enable = 'on';
                app.UseGPUCheckBox.Value = true;
            catch ME
                app.GPUInfoLabel.Text = sprintf('GPU nije moguće inicijalizovati: %s', ME.message);
            end
        end

        function setBusy(app, isBusy, statusText)
            % Lock the controls while training runs
            if isBusy
                state = 'off';
            else
                state = 'on';
            end
            controls = [app.TrainingParamsPanel.Children; app.ValidationPanel.Children];
            for k = 1:numel(controls)
                if isprop(controls(k), 'Enable')
                    controls(k).Enable = state;
                end
            end
            app.StartTrainingButton.Enable = state;
            % The GPU box stays disabled if probeGPU found no usable GPU
            if app.GPUAvailable
                app.UseGPUCheckBox.Enable = state;
            end
            app.StatusLabel.Text = "Status: " + statusText;
            drawnow;
        end

        function result = trainAndSaveCNN(app, p, savePath)
            % Local copy: descending into a wrapper folder must not change app.DatasetPath
            datasetPath = app.DatasetPath;
            subDirs = dir(datasetPath);
            subDirs = subDirs([subDirs.isdir] & ~startsWith({subDirs.name}, '.'));
            hasTrain = any(strcmpi({subDirs.name}, 'training'));
            hasTest  = any(strcmpi({subDirs.name}, 'testing'));
            if ~(hasTrain && hasTest) && numel(subDirs) == 1
                datasetPath = fullfile(datasetPath, subDirs(1).name);
            end

            imdsAll = imageDatastore(fullfile(datasetPath, 'training'), ...
                'IncludeSubfolders', true, ...
                'LabelSource', 'foldernames');
            imdsTest = imageDatastore(fullfile(datasetPath, 'testing'), ...
                'IncludeSubfolders', true, ...
                'LabelSource', 'foldernames');

            classNames = string(categories(imdsAll.Labels));
            numClasses = numel(classNames);

            % Size/channels of the data on disk: manifest first, then the parent's choice, then a sample
            manifestFile = fullfile(datasetPath, 'photolab_dataset.mat');
            [~, datasetName] = fileparts(datasetPath);
            if isfile(manifestFile)
                manifest = load(manifestFile);
                dataSize = [manifest.imageSize manifest.channels];
            elseif numel(app.InputDimensions) == 3
                dataSize = app.InputDimensions;
            else
                sample = imread(imdsAll.Files{1});
                dataSize = [size(sample, 1) size(sample, 2) size(sample, 3)];
            end

            % Validation split
            if p.validationFraction > 0
                [imdsTrain, imdsVal] = splitEachLabel(imdsAll, 1 - p.validationFraction, 'randomized');
            else
                imdsTrain = imdsAll;
                imdsVal = [];
            end

            [layers, netInputSize, normalization] = getLayers(app, app.Architecture, dataSize, numClasses, app.Normalization);

            % Reconcile disk data with what the network needs (size and channels)
            if netInputSize(3) == 3 && dataSize(3) == 1
                colorPrep = 'gray2rgb';
            elseif netInputSize(3) == 1 && dataSize(3) == 3
                colorPrep = 'rgb2gray';
            else
                colorPrep = 'none';
            end

            if p.augment
                shift = max(1, round(netInputSize(1) / 16));
                augmenter = imageDataAugmenter( ...
                    'RandXReflection', true, ...
                    'RandXTranslation', [-shift shift], ...
                    'RandYTranslation', [-shift shift]);
                augTrain = augmentedImageDatastore(netInputSize(1:2), imdsTrain, ...
                    'ColorPreprocessing', colorPrep, 'DataAugmentation', augmenter);
            else
                augTrain = augmentedImageDatastore(netInputSize(1:2), imdsTrain, ...
                    'ColorPreprocessing', colorPrep);
            end
            if isempty(imdsVal)
                augVal = [];
            else
                augVal = augmentedImageDatastore(netInputSize(1:2), imdsVal, ...
                    'ColorPreprocessing', colorPrep);
            end
            augTest = augmentedImageDatastore(netInputSize(1:2), imdsTest, ...
                'ColorPreprocessing', colorPrep);

            options = getTrainingOptions(app, p, augVal);

            trainTimer = tic;
            [net, info] = trainNetwork(augTrain, layers, options);
            result.trainingTime = toc(trainTimer);

            % Evaluate on the held-out test split
            setBusy(app, true, 'Evaluacija na test skupu...');
            preds = classify(net, augTest, 'MiniBatchSize', p.batchSize, ...
                'ExecutionEnvironment', p.executionEnvironment);
            accuracy = mean(preds == imdsTest.Labels);
            fprintf("Test Accuracy: %.2f%%\n", accuracy * 100);

            % Save trained model with everything inference and evaluation need
            inputSize = netInputSize;
            architecture = app.Architecture;
            yTrue = imdsTest.Labels;
            yPred = preds;
            testFiles = imdsTest.Files;
            save(savePath, 'net', 'accuracy', 'classNames', 'inputSize', ...
                'normalization', 'architecture', 'datasetName', ...
                'yTrue', 'yPred', 'testFiles');

            result.accuracy = accuracy;
            if isfield(info, 'FinalValidationAccuracy') && ~isempty(info.FinalValidationAccuracy) ...
                    && ~isnan(info.FinalValidationAccuracy)
                result.validationAccuracy = info.FinalValidationAccuracy / 100;
            else
                result.validationAccuracy = NaN;
            end
        end

    end

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            movegui(app.UIFigure, 'center');
            OptimizerDropDownValueChanged(app, []);
            probeGPU(app);
        end

        % Value changed function: OptimizerDropDown
        function OptimizerDropDownValueChanged(app, event)
            % Show only the hyperparameters the selected optimizer uses
            optimizer = app.OptimizerDropDown.Value;
            isSgdm = strcmp(optimizer, 'sgdm');
            isAdam = strcmp(optimizer, 'adam');
            isRms  = strcmp(optimizer, 'rmsprop');

            app.MomentumLabel.Visible = isSgdm;
            app.MomentumEditField.Visible = isSgdm;
            app.Beta1Label.Visible = isAdam;
            app.Beta1EditField.Visible = isAdam;
            app.Beta2Label.Visible = isAdam;
            app.Beta2EditField.Visible = isAdam;
            app.RMSDecayLabel.Visible = isRms;
            app.RMSDecayEditField.Visible = isRms;
            app.EpsilonLabel.Visible = isAdam || isRms;
            app.EpsilonEditField.Visible = isAdam || isRms;

            % Epsilon takes the first free row under the optimizer-specific fields
            if isAdam
                epsilonY = 70;
            else
                epsilonY = 106;
            end
            app.EpsilonLabel.Position(2) = epsilonY;
            app.EpsilonEditField.Position(2) = epsilonY;
        end

        % Button pushed function: StartTrainingButton
        function StartTrainingButtonPushed(app, event)
            if isempty(app.Architecture) || isempty(app.DatasetPath)
                uialert(app.UIFigure, 'Arhitektura ili dataset nisu izabrani!', 'Warning');
                return;
            end
            p = collectParams(app);

            % Choose where to save
            [~, datasetName] = fileparts(app.DatasetPath);
            defaultName = regexprep(sprintf('%s_%s.mat', app.Architecture, datasetName), '[^\w.]', '_');
            [file, path] = uiputfile(defaultName, 'Save Trained Model As');
            if isequal(file, 0)
                uialert(app.UIFigure, 'Treniranje otkazano. Fajl nije izabran.', 'Otkazano');
                return;
            end
            savePath = fullfile(path, file);

            app.AccuracyLabel.Text = '—';
            app.ValAccuracyValueLabel.Text = '—';
            app.TrainingTimeValueLabel.Text = '—';
            app.SavedModelPathLabel.Text = '';
            setBusy(app, true, sprintf('Treniranje u toku (%s, %s)...', p.optimizer, upper(p.executionEnvironment)));

            try
                result = trainAndSaveCNN(app, p, savePath);
            catch ME
                setBusy(app, false, 'Greška tokom treniranja');
                uialert(app.UIFigure, ME.message, 'Greška');
                return;
            end

            app.AccuracyLabel.Text = sprintf('%.2f%%', result.accuracy * 100);
            if isnan(result.validationAccuracy)
                app.ValAccuracyValueLabel.Text = '—';
            else
                app.ValAccuracyValueLabel.Text = sprintf('%.2f%%', result.validationAccuracy * 100);
            end
            app.TrainingTimeValueLabel.Text = char(duration(0, 0, result.trainingTime, 'Format', 'hh:mm:ss'));
            app.SavedModelPathLabel.Text = savePath;
            setBusy(app, false, 'Treniranje završeno, model sačuvan');

            uialert(app.UIFigure, 'Treniranje završeno i model sačuvan.', 'Uspjeh', 'Icon', 'success');
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 1200 760];
            app.UIFigure.Name = 'Treniranje CNN modela';

            % Create TitleLabel
            app.TitleLabel = uilabel(app.UIFigure);
            app.TitleLabel.FontSize = 22;
            app.TitleLabel.FontWeight = 'bold';
            app.TitleLabel.Position = [24 704 800 32];
            app.TitleLabel.Text = 'Treniranje CNN modela';

            %% Konfiguracija (read-only summary of the menu choices)

            % Create ConfigPanel
            app.ConfigPanel = uipanel(app.UIFigure);
            app.ConfigPanel.Title = 'Konfiguracija';
            app.ConfigPanel.FontSize = 14;
            app.ConfigPanel.FontWeight = 'bold';
            app.ConfigPanel.Position = [24 504 372 180];

            % Create ArchNameLabel
            app.ArchNameLabel = uilabel(app.ConfigPanel);
            app.ArchNameLabel.FontSize = 12;
            app.ArchNameLabel.Position = [16 122 110 24];
            app.ArchNameLabel.Text = 'Arhitektura:';

            % Create ArchValueLabel
            app.ArchValueLabel = uilabel(app.ConfigPanel);
            app.ArchValueLabel.FontSize = 12;
            app.ArchValueLabel.FontWeight = 'bold';
            app.ArchValueLabel.Position = [130 122 226 24];
            app.ArchValueLabel.Text = '—';

            % Create DatasetNameLabel
            app.DatasetNameLabel = uilabel(app.ConfigPanel);
            app.DatasetNameLabel.FontSize = 12;
            app.DatasetNameLabel.Position = [16 86 110 24];
            app.DatasetNameLabel.Text = 'Dataset:';

            % Create DatasetValueLabel
            app.DatasetValueLabel = uilabel(app.ConfigPanel);
            app.DatasetValueLabel.FontSize = 12;
            app.DatasetValueLabel.FontWeight = 'bold';
            app.DatasetValueLabel.Position = [130 86 226 24];
            app.DatasetValueLabel.Text = '—';

            % Create InputNameLabel
            app.InputNameLabel = uilabel(app.ConfigPanel);
            app.InputNameLabel.FontSize = 12;
            app.InputNameLabel.Position = [16 50 110 24];
            app.InputNameLabel.Text = 'Ulaz mreže:';

            % Create InputValueLabel
            app.InputValueLabel = uilabel(app.ConfigPanel);
            app.InputValueLabel.FontSize = 12;
            app.InputValueLabel.FontWeight = 'bold';
            app.InputValueLabel.Position = [130 50 226 24];
            app.InputValueLabel.Text = '—';

            % Create NormNameLabel
            app.NormNameLabel = uilabel(app.ConfigPanel);
            app.NormNameLabel.FontSize = 12;
            app.NormNameLabel.Position = [16 14 110 24];
            app.NormNameLabel.Text = 'Normalizacija:';

            % Create NormValueLabel
            app.NormValueLabel = uilabel(app.ConfigPanel);
            app.NormValueLabel.FontSize = 12;
            app.NormValueLabel.FontWeight = 'bold';
            app.NormValueLabel.Position = [130 14 226 24];
            app.NormValueLabel.Text = '—';

            %% Hardver

            % Create HardwarePanel
            app.HardwarePanel = uipanel(app.UIFigure);
            app.HardwarePanel.Title = 'Hardver';
            app.HardwarePanel.FontSize = 14;
            app.HardwarePanel.FontWeight = 'bold';
            app.HardwarePanel.Position = [24 304 372 184];

            % Create UseGPUCheckBox
            app.UseGPUCheckBox = uicheckbox(app.HardwarePanel);
            app.UseGPUCheckBox.FontSize = 12;
            app.UseGPUCheckBox.Position = [16 126 340 24];
            app.UseGPUCheckBox.Text = 'Koristi GPU (NVIDIA CUDA)';

            % Create GPUInfoLabel
            app.GPUInfoLabel = uilabel(app.HardwarePanel);
            app.GPUInfoLabel.FontSize = 12;
            app.GPUInfoLabel.WordWrap = 'on';
            app.GPUInfoLabel.VerticalAlignment = 'top';
            app.GPUInfoLabel.Position = [16 12 340 104];
            app.GPUInfoLabel.Text = 'Provjera GPU-a...';

            %% Hiperparametri

            % Create TrainingParamsPanel
            app.TrainingParamsPanel = uipanel(app.UIFigure);
            app.TrainingParamsPanel.Title = 'Hiperparametri';
            app.TrainingParamsPanel.FontSize = 14;
            app.TrainingParamsPanel.FontWeight = 'bold';
            app.TrainingParamsPanel.Position = [412 304 372 380];

            % Create LearningRateLabel
            app.LearningRateLabel = uilabel(app.TrainingParamsPanel);
            app.LearningRateLabel.FontSize = 12;
            app.LearningRateLabel.Position = [16 322 150 24];
            app.LearningRateLabel.Text = 'Learning Rate:';

            % Create LearningRateEditField
            app.LearningRateEditField = uieditfield(app.TrainingParamsPanel, 'numeric');
            app.LearningRateEditField.Limits = [1e-06 1];
            app.LearningRateEditField.ValueDisplayFormat = '%.6g';
            app.LearningRateEditField.FontSize = 12;
            app.LearningRateEditField.Position = [180 322 170 24];
            app.LearningRateEditField.Value = 0.001;

            % Create BatchSizeLabel
            app.BatchSizeLabel = uilabel(app.TrainingParamsPanel);
            app.BatchSizeLabel.FontSize = 12;
            app.BatchSizeLabel.Position = [16 286 150 24];
            app.BatchSizeLabel.Text = 'Batch Size:';

            % Create BatchSizeEditField
            app.BatchSizeEditField = uieditfield(app.TrainingParamsPanel, 'numeric');
            app.BatchSizeEditField.Limits = [1 1024];
            app.BatchSizeEditField.RoundFractionalValues = 'on';
            app.BatchSizeEditField.FontSize = 12;
            app.BatchSizeEditField.Position = [180 286 170 24];
            app.BatchSizeEditField.Value = 64;

            % Create EpochsLabel
            app.EpochsLabel = uilabel(app.TrainingParamsPanel);
            app.EpochsLabel.FontSize = 12;
            app.EpochsLabel.Position = [16 250 150 24];
            app.EpochsLabel.Text = 'Epochs:';

            % Create EpochsSpinner
            app.EpochsSpinner = uispinner(app.TrainingParamsPanel);
            app.EpochsSpinner.Limits = [1 500];
            app.EpochsSpinner.RoundFractionalValues = 'on';
            app.EpochsSpinner.FontSize = 12;
            app.EpochsSpinner.Position = [180 250 170 24];
            app.EpochsSpinner.Value = 5;

            % Create WeightDecayLabel
            app.WeightDecayLabel = uilabel(app.TrainingParamsPanel);
            app.WeightDecayLabel.FontSize = 12;
            app.WeightDecayLabel.Position = [16 214 150 24];
            app.WeightDecayLabel.Text = 'Weight Decay (L2):';

            % Create WeightDecayEditField
            app.WeightDecayEditField = uieditfield(app.TrainingParamsPanel, 'numeric');
            app.WeightDecayEditField.Limits = [0 0.1];
            app.WeightDecayEditField.ValueDisplayFormat = '%.6g';
            app.WeightDecayEditField.FontSize = 12;
            app.WeightDecayEditField.Position = [180 214 170 24];
            app.WeightDecayEditField.Value = 0.0005;

            % Create OptimizerLabel
            app.OptimizerLabel = uilabel(app.TrainingParamsPanel);
            app.OptimizerLabel.FontSize = 12;
            app.OptimizerLabel.Position = [16 178 150 24];
            app.OptimizerLabel.Text = 'Optimizer:';

            % Create OptimizerDropDown
            app.OptimizerDropDown = uidropdown(app.TrainingParamsPanel);
            app.OptimizerDropDown.Items = {'sgdm', 'adam', 'rmsprop'};
            app.OptimizerDropDown.ValueChangedFcn = createCallbackFcn(app, @OptimizerDropDownValueChanged, true);
            app.OptimizerDropDown.FontSize = 12;
            app.OptimizerDropDown.Position = [180 178 170 24];
            app.OptimizerDropDown.Value = 'sgdm';

            % Create MomentumLabel (sgdm)
            app.MomentumLabel = uilabel(app.TrainingParamsPanel);
            app.MomentumLabel.FontSize = 12;
            app.MomentumLabel.Position = [16 142 150 24];
            app.MomentumLabel.Text = 'Momentum:';

            % Create MomentumEditField
            app.MomentumEditField = uieditfield(app.TrainingParamsPanel, 'numeric');
            app.MomentumEditField.Limits = [0 0.999];
            app.MomentumEditField.FontSize = 12;
            app.MomentumEditField.Position = [180 142 170 24];
            app.MomentumEditField.Value = 0.9;

            % Create Beta1Label (adam)
            app.Beta1Label = uilabel(app.TrainingParamsPanel);
            app.Beta1Label.FontSize = 12;
            app.Beta1Label.Position = [16 142 150 24];
            app.Beta1Label.Text = 'Beta1 (gradient decay):';

            % Create Beta1EditField
            app.Beta1EditField = uieditfield(app.TrainingParamsPanel, 'numeric');
            app.Beta1EditField.Limits = [0 0.9999];
            app.Beta1EditField.FontSize = 12;
            app.Beta1EditField.Position = [180 142 170 24];
            app.Beta1EditField.Value = 0.9;

            % Create Beta2Label (adam)
            app.Beta2Label = uilabel(app.TrainingParamsPanel);
            app.Beta2Label.FontSize = 12;
            app.Beta2Label.Position = [16 106 150 24];
            app.Beta2Label.Text = 'Beta2 (sq. grad. decay):';

            % Create Beta2EditField
            app.Beta2EditField = uieditfield(app.TrainingParamsPanel, 'numeric');
            app.Beta2EditField.Limits = [0 0.99999];
            app.Beta2EditField.FontSize = 12;
            app.Beta2EditField.Position = [180 106 170 24];
            app.Beta2EditField.Value = 0.999;

            % Create RMSDecayLabel (rmsprop)
            app.RMSDecayLabel = uilabel(app.TrainingParamsPanel);
            app.RMSDecayLabel.FontSize = 12;
            app.RMSDecayLabel.Position = [16 142 150 24];
            app.RMSDecayLabel.Text = 'Decay rate:';

            % Create RMSDecayEditField
            app.RMSDecayEditField = uieditfield(app.TrainingParamsPanel, 'numeric');
            app.RMSDecayEditField.Limits = [0 0.99999];
            app.RMSDecayEditField.FontSize = 12;
            app.RMSDecayEditField.Position = [180 142 170 24];
            app.RMSDecayEditField.Value = 0.9;

            % Create EpsilonLabel (adam, rmsprop; row set by OptimizerDropDownValueChanged)
            app.EpsilonLabel = uilabel(app.TrainingParamsPanel);
            app.EpsilonLabel.FontSize = 12;
            app.EpsilonLabel.Position = [16 70 150 24];
            app.EpsilonLabel.Text = 'Epsilon:';

            % Create EpsilonEditField
            app.EpsilonEditField = uieditfield(app.TrainingParamsPanel, 'numeric');
            app.EpsilonEditField.Limits = [1e-12 1];
            app.EpsilonEditField.ValueDisplayFormat = '%.1e';
            app.EpsilonEditField.FontSize = 12;
            app.EpsilonEditField.Position = [180 70 170 24];
            app.EpsilonEditField.Value = 1e-08;

            %% Validacija i augmentacija

            % Create ValidationPanel
            app.ValidationPanel = uipanel(app.UIFigure);
            app.ValidationPanel.Title = 'Validacija i augmentacija';
            app.ValidationPanel.FontSize = 14;
            app.ValidationPanel.FontWeight = 'bold';
            app.ValidationPanel.Position = [800 304 376 380];

            % Create ValidationSplitLabel
            app.ValidationSplitLabel = uilabel(app.ValidationPanel);
            app.ValidationSplitLabel.FontSize = 12;
            app.ValidationSplitLabel.Position = [16 322 170 24];
            app.ValidationSplitLabel.Text = 'Validacioni skup (%):';

            % Create ValidationSplitSpinner
            app.ValidationSplitSpinner = uispinner(app.ValidationPanel);
            app.ValidationSplitSpinner.Limits = [0 50];
            app.ValidationSplitSpinner.RoundFractionalValues = 'on';
            app.ValidationSplitSpinner.FontSize = 12;
            app.ValidationSplitSpinner.Position = [190 322 170 24];
            app.ValidationSplitSpinner.Value = 10;

            % Create ValidationFrequencyLabel
            app.ValidationFrequencyLabel = uilabel(app.ValidationPanel);
            app.ValidationFrequencyLabel.FontSize = 12;
            app.ValidationFrequencyLabel.Position = [16 286 170 24];
            app.ValidationFrequencyLabel.Text = 'Validation Frequency (iter.):';

            % Create ValidationFrequencySpinner
            app.ValidationFrequencySpinner = uispinner(app.ValidationPanel);
            app.ValidationFrequencySpinner.Limits = [1 10000];
            app.ValidationFrequencySpinner.RoundFractionalValues = 'on';
            app.ValidationFrequencySpinner.FontSize = 12;
            app.ValidationFrequencySpinner.Position = [190 286 170 24];
            app.ValidationFrequencySpinner.Value = 50;

            % Create ValidationPatienceLabel
            app.ValidationPatienceLabel = uilabel(app.ValidationPanel);
            app.ValidationPatienceLabel.FontSize = 12;
            app.ValidationPatienceLabel.Position = [16 250 170 24];
            app.ValidationPatienceLabel.Text = 'Validation Patience (0 = off):';

            % Create ValidationPatienceSpinner
            app.ValidationPatienceSpinner = uispinner(app.ValidationPanel);
            app.ValidationPatienceSpinner.Limits = [0 100];
            app.ValidationPatienceSpinner.RoundFractionalValues = 'on';
            app.ValidationPatienceSpinner.FontSize = 12;
            app.ValidationPatienceSpinner.Position = [190 250 170 24];
            app.ValidationPatienceSpinner.Value = 5;

            % Create GradientThresholdLabel
            app.GradientThresholdLabel = uilabel(app.ValidationPanel);
            app.GradientThresholdLabel.FontSize = 12;
            app.GradientThresholdLabel.Position = [16 214 170 24];
            app.GradientThresholdLabel.Text = 'Gradient Threshold (0 = off):';

            % Create GradientThresholdEditField
            app.GradientThresholdEditField = uieditfield(app.ValidationPanel, 'numeric');
            app.GradientThresholdEditField.Limits = [0 100];
            app.GradientThresholdEditField.FontSize = 12;
            app.GradientThresholdEditField.Position = [190 214 170 24];
            app.GradientThresholdEditField.Value = 0;

            % Create ShuffleLabel
            app.ShuffleLabel = uilabel(app.ValidationPanel);
            app.ShuffleLabel.FontSize = 12;
            app.ShuffleLabel.Position = [16 178 170 24];
            app.ShuffleLabel.Text = 'Shuffle:';

            % Create ShuffleDropDown
            app.ShuffleDropDown = uidropdown(app.ValidationPanel);
            app.ShuffleDropDown.Items = {'every-epoch', 'once', 'never'};
            app.ShuffleDropDown.FontSize = 12;
            app.ShuffleDropDown.Position = [190 178 170 24];
            app.ShuffleDropDown.Value = 'every-epoch';

            % Create PlotsLabel
            app.PlotsLabel = uilabel(app.ValidationPanel);
            app.PlotsLabel.FontSize = 12;
            app.PlotsLabel.Position = [16 142 170 24];
            app.PlotsLabel.Text = 'Plots:';

            % Create PlotsDropDown
            app.PlotsDropDown = uidropdown(app.ValidationPanel);
            app.PlotsDropDown.Items = {'training-progress', 'none'};
            app.PlotsDropDown.FontSize = 12;
            app.PlotsDropDown.Position = [190 142 170 24];
            app.PlotsDropDown.Value = 'training-progress';

            % Create AugmentationCheckBox
            app.AugmentationCheckBox = uicheckbox(app.ValidationPanel);
            app.AugmentationCheckBox.FontSize = 12;
            app.AugmentationCheckBox.Position = [16 106 344 24];
            app.AugmentationCheckBox.Text = 'Augmentacija podataka';
            app.AugmentationCheckBox.Value = false;

            % Create AugmentationHintLabel
            app.AugmentationHintLabel = uilabel(app.ValidationPanel);
            app.AugmentationHintLabel.FontSize = 11;
            app.AugmentationHintLabel.WordWrap = 'on';
            app.AugmentationHintLabel.VerticalAlignment = 'top';
            app.AugmentationHintLabel.Position = [16 44 344 56];
            app.AugmentationHintLabel.Text = ['Horizontalno zrcaljenje i mala translacija. ' ...
                'Preporučeno za CIFAR; za MNIST cifre isključiti (zrcaljena cifra nije ista cifra).'];

            %% Rezultati

            % Create ResultsPanel
            app.ResultsPanel = uipanel(app.UIFigure);
            app.ResultsPanel.Title = 'Rezultati';
            app.ResultsPanel.FontSize = 14;
            app.ResultsPanel.FontWeight = 'bold';
            app.ResultsPanel.Position = [24 24 1152 264];

            % Create StatusLabel
            app.StatusLabel = uilabel(app.ResultsPanel);
            app.StatusLabel.FontSize = 13;
            app.StatusLabel.Position = [16 196 880 24];
            app.StatusLabel.Text = 'Status: Spremno';

            % Create TestingAccuracyLabel
            app.TestingAccuracyLabel = uilabel(app.ResultsPanel);
            app.TestingAccuracyLabel.FontSize = 13;
            app.TestingAccuracyLabel.Position = [16 144 260 28];
            app.TestingAccuracyLabel.Text = 'Tačnost na test skupu:';

            % Create AccuracyLabel
            app.AccuracyLabel = uilabel(app.ResultsPanel);
            app.AccuracyLabel.FontSize = 20;
            app.AccuracyLabel.FontWeight = 'bold';
            app.AccuracyLabel.FontColor = [0.18 0.55 0.34];
            app.AccuracyLabel.Position = [280 142 200 32];
            app.AccuracyLabel.Text = '—';

            % Create ValidationAccuracyLabel
            app.ValidationAccuracyLabel = uilabel(app.ResultsPanel);
            app.ValidationAccuracyLabel.FontSize = 13;
            app.ValidationAccuracyLabel.Position = [16 100 260 28];
            app.ValidationAccuracyLabel.Text = 'Tačnost na validacionom skupu:';

            % Create ValAccuracyValueLabel
            app.ValAccuracyValueLabel = uilabel(app.ResultsPanel);
            app.ValAccuracyValueLabel.FontSize = 20;
            app.ValAccuracyValueLabel.Position = [280 98 200 32];
            app.ValAccuracyValueLabel.Text = '—';

            % Create TrainingTimeLabel
            app.TrainingTimeLabel = uilabel(app.ResultsPanel);
            app.TrainingTimeLabel.FontSize = 13;
            app.TrainingTimeLabel.Position = [16 56 260 28];
            app.TrainingTimeLabel.Text = 'Vrijeme treniranja:';

            % Create TrainingTimeValueLabel
            app.TrainingTimeValueLabel = uilabel(app.ResultsPanel);
            app.TrainingTimeValueLabel.FontSize = 20;
            app.TrainingTimeValueLabel.Position = [280 54 200 32];
            app.TrainingTimeValueLabel.Text = '—';

            % Create SavedModelLabel
            app.SavedModelLabel = uilabel(app.ResultsPanel);
            app.SavedModelLabel.FontSize = 12;
            app.SavedModelLabel.Position = [16 16 60 24];
            app.SavedModelLabel.Text = 'Model:';

            % Create SavedModelPathLabel
            app.SavedModelPathLabel = uilabel(app.ResultsPanel);
            app.SavedModelPathLabel.FontName = 'Courier New';
            app.SavedModelPathLabel.FontSize = 11;
            app.SavedModelPathLabel.Position = [80 16 820 24];
            app.SavedModelPathLabel.Text = '';

            % Create StartTrainingButton
            app.StartTrainingButton = uibutton(app.ResultsPanel, 'push');
            app.StartTrainingButton.ButtonPushedFcn = createCallbackFcn(app, @StartTrainingButtonPushed, true);
            app.StartTrainingButton.BackgroundColor = [0.2 0.45 0.75];
            app.StartTrainingButton.FontColor = [1 1 1];
            app.StartTrainingButton.FontSize = 13;
            app.StartTrainingButton.FontWeight = 'bold';
            app.StartTrainingButton.Position = [928 16 200 44];
            app.StartTrainingButton.Text = 'Pokreni treniranje';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = TrainingCNN

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
