function result = trainCNNModel(datasetPath, architecture, normalization, p, inputDimensions, progressFcn)
% trainCNNModel Train a PhotoLab classifier and evaluate it on testing/
%   result = trainCNNModel(datasetPath, architecture, normalization, p, inputDimensions, progressFcn)
%
%   The one code path behind both TrainingCNN and the experiment scripts.
%     datasetPath      dataset folder (photolab_dataset.mat, training/, testing/)
%     architecture     'LeNet' or 'AlexNet' (see getLayers)
%     normalization    'None' / 'MinMax' / 'Mean-Std'
%     p                parameter struct, see defaultTrainingParams
%                      (validationFrequency 0 = once per epoch)
%     inputDimensions  [H W C] fallback when the folder has no manifest; [] is fine
%     progressFcn      optional handle, called with a struct with fields phase
%                      ('training' | 'evaluating') and message; [] = silent
%
%   result fields: net, info, accuracy, classNames, inputSize, normalization,
%   architecture, datasetName, yTrue, yPred, testFiles, trainingTime, testTime
%   (seconds), validationAccuracy (fraction, NaN if none), numLearnables.
%   Save it with saveCNNModel.

    if nargin < 5, inputDimensions = []; end
    if nargin < 6, progressFcn = []; end
    architecture = char(architecture);
    normalization = char(normalization);

    s = loadDatasetSplits(datasetPath, p, inputDimensions);
    numClasses = numel(s.classNames);

    [layers, netInputSize, normalization] = getLayers(architecture, s.dataSize, numClasses, normalization);
    [augTrain, augVal, augTest] = buildAugmentedDatastores(s, netInputSize, p.augment);

    if isfield(p, 'validationFrequency') && p.validationFrequency == 0
        p.validationFrequency = max(1, floor(numel(s.imdsTrain.Files) / p.batchSize));
    end
    options = getTrainingOptions(p, augVal);

    report(progressFcn, 'training', 'Treniranje u toku...');
    trainTimer = tic;
    [net, info] = trainNetwork(augTrain, layers, options);
    trainingTime = toc(trainTimer);

    report(progressFcn, 'evaluating', 'Evaluacija na test skupu...');
    yTrue = s.imdsTest.Labels;
    [accuracy, yPred, testTime] = evaluateOnTestSet(net, augTest, yTrue, p);

    if isfield(info, 'FinalValidationAccuracy') && ~isempty(info.FinalValidationAccuracy) ...
            && ~isnan(info.FinalValidationAccuracy)
        validationAccuracy = info.FinalValidationAccuracy / 100;
    else
        validationAccuracy = NaN;
    end

    result = struct( ...
        'net', net, ...
        'info', info, ...
        'accuracy', accuracy, ...
        'classNames', s.classNames, ...
        'inputSize', netInputSize, ...
        'normalization', normalization, ...
        'architecture', architecture, ...
        'datasetName', s.datasetName, ...
        'yTrue', yTrue, ...
        'yPred', yPred, ...
        'testFiles', {s.imdsTest.Files}, ...
        'trainingTime', trainingTime, ...
        'testTime', testTime, ...
        'validationAccuracy', validationAccuracy, ...
        'numLearnables', countLearnables(net));
end

function report(progressFcn, phase, message)
    if ~isempty(progressFcn)
        progressFcn(struct('phase', phase, 'message', message));
    end
end
