function [augTrain, augVal, augTest] = buildAugmentedDatastores(s, netInputSize, augment)
% buildAugmentedDatastores Wrap the splits in augmentedImageDatastore
%   Reconciles the size and channels on disk (s.dataSize) with what the network
%   needs (netInputSize). augment adds a horizontal flip and a small translation
%   to the training split only. augVal is [] when there is no validation split.
%
%   metrics/evaluateModelOnTestSet and generative/evaluateWithClassifier rebuild
%   the same colour preprocessing; keep them in step.

    dataSize = s.dataSize;
    if netInputSize(3) == 3 && dataSize(3) == 1
        colorPrep = 'gray2rgb';
    elseif netInputSize(3) == 1 && dataSize(3) == 3
        colorPrep = 'rgb2gray';
    else
        colorPrep = 'none';
    end

    if augment
        shift = max(1, round(netInputSize(1) / 16));
        augmenter = imageDataAugmenter( ...
            'RandXReflection', true, ...
            'RandXTranslation', [-shift shift], ...
            'RandYTranslation', [-shift shift]);
        augTrain = augmentedImageDatastore(netInputSize(1:2), s.imdsTrain, ...
            'ColorPreprocessing', colorPrep, 'DataAugmentation', augmenter);
    else
        augTrain = augmentedImageDatastore(netInputSize(1:2), s.imdsTrain, ...
            'ColorPreprocessing', colorPrep);
    end
    if isempty(s.imdsVal)
        augVal = [];
    else
        augVal = augmentedImageDatastore(netInputSize(1:2), s.imdsVal, ...
            'ColorPreprocessing', colorPrep);
    end
    augTest = augmentedImageDatastore(netInputSize(1:2), s.imdsTest, ...
        'ColorPreprocessing', colorPrep);
end
