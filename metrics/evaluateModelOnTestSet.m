function [yTrue, yPred, files] = evaluateModelOnTestSet(net, datasetPath, miniBatchSize)
% evaluateModelOnTestSet Classify a dataset's testing/ split with a trained network
%   [yTrue, yPred, files] = evaluateModelOnTestSet(net, datasetPath)
%
%   datasetPath must contain photolab_dataset.mat and a testing/ folder with
%   one subfolder per class. The images go through the same preprocessing as
%   in TrainingCNN: augmentedImageDatastore to the net's input size, with the
%   colour conversion needed between the channels on disk and the net input.
%   yTrue and yPred are categorical with the network's class order.

    if nargin < 3
        miniBatchSize = 128;
    end

    manifestFile = fullfile(datasetPath, 'photolab_dataset.mat');
    if ~isfile(manifestFile)
        error('PhotoLab:noManifest', ...
            'Folder ne sadrži photolab_dataset.mat. Izaberite dataset pripremljen u PhotoLab-u.');
    end
    testDir = fullfile(datasetPath, 'testing');
    if ~isfolder(testDir)
        error('PhotoLab:noTesting', 'Dataset nema folder "testing".');
    end

    manifest = load(manifestFile);
    imds = imageDatastore(testDir, 'IncludeSubfolders', true, 'LabelSource', 'foldernames');
    if isempty(imds.Files)
        error('PhotoLab:noTesting', 'Folder "testing" ne sadrži slike.');
    end

    netClasses = string(net.Layers(end).Classes);
    datasetClasses = string(categories(imds.Labels));
    if ~isequal(sort(netClasses(:)), sort(datasetClasses(:)))
        error('PhotoLab:classMismatch', ...
            'Klase modela (%d) ne odgovaraju klasama dataseta (%d).', ...
            numel(netClasses), numel(datasetClasses));
    end

    inputSize = net.Layers(1).InputSize;
    if inputSize(3) == 3 && manifest.channels == 1
        colorPrep = 'gray2rgb';
    elseif inputSize(3) == 1 && manifest.channels == 3
        colorPrep = 'rgb2gray';
    else
        colorPrep = 'none';
    end
    augTest = augmentedImageDatastore(inputSize(1:2), imds, 'ColorPreprocessing', colorPrep);

    predicted = classify(net, augTest, 'MiniBatchSize', miniBatchSize);

    yTrue = categorical(string(imds.Labels), netClasses);
    yPred = categorical(string(predicted), netClasses);
    files = imds.Files;
end
