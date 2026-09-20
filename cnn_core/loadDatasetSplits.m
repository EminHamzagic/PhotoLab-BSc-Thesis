function s = loadDatasetSplits(datasetPath, p, inputDimensions)
% loadDatasetSplits Datastores of a PhotoLab dataset: train / validation / test
%   s = loadDatasetSplits(datasetPath, p, inputDimensions)
%
%   datasetPath      folder with training/ and testing/ (one subfolder per class)
%   p                training parameter struct; uses validationFraction and the
%                    optional subsetFraction (< 1 keeps a stratified fraction of
%                    both training/ and testing/, used by the benchmark)
%   inputDimensions  [H W C] chosen in the dataset window; only a fallback when
%                    the folder has no photolab_dataset.mat
%
%   Returns imdsTrain, imdsVal ([] when validationFraction is 0), imdsTest,
%   classNames (string), dataSize ([H W C] on disk), datasetName, datasetPath.

    [datasetPath, datasetName] = resolveDatasetPath(datasetPath);

    imdsAll = imageDatastore(fullfile(datasetPath, 'training'), ...
        'IncludeSubfolders', true, ...
        'LabelSource', 'foldernames');
    imdsTest = imageDatastore(fullfile(datasetPath, 'testing'), ...
        'IncludeSubfolders', true, ...
        'LabelSource', 'foldernames');

    if isfield(p, 'subsetFraction') && p.subsetFraction < 1
        imdsAll = splitEachLabel(imdsAll, p.subsetFraction, 'randomized');
        imdsTest = splitEachLabel(imdsTest, p.subsetFraction, 'randomized');
    end

    classNames = string(categories(imdsAll.Labels));

    % Size/channels of the data on disk: manifest first, then the parent's choice, then a sample
    manifestFile = fullfile(datasetPath, 'photolab_dataset.mat');
    if isfile(manifestFile)
        manifest = load(manifestFile);
        dataSize = [manifest.imageSize manifest.channels];
    elseif numel(inputDimensions) == 3
        dataSize = inputDimensions;
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

    s = struct('imdsTrain', imdsTrain, 'imdsVal', imdsVal, 'imdsTest', imdsTest, ...
        'classNames', classNames, 'dataSize', dataSize, ...
        'datasetName', datasetName, 'datasetPath', datasetPath);
end
