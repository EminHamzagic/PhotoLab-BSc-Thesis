function data = loadGenerativeDataset(datasetPath, maxImages, seed, progressFcn)
% loadGenerativeDataset Read the training/ images of a PhotoLab dataset into memory
%   data = loadGenerativeDataset(datasetPath, maxImages, seed, progressFcn)
%
%   datasetPath  folder with photolab_dataset.mat and training/<class>/*.png
%   maxImages    random subsample size, 0 (or >= number of files) = all images
%   seed         seed of the subsampling (does not touch the global RNG)
%   progressFcn  optional, called with a fraction in [0,1] while reading
%
%   data.X is a single H x W x C x N array in [0,1], allocated once (no copies).
%   Also returned: imageSize, channels, classNames, datasetName, numImages.

    if nargin < 2 || isempty(maxImages), maxImages = 0; end
    if nargin < 3 || isempty(seed), seed = 1; end
    if nargin < 4, progressFcn = []; end

    manifestFile = fullfile(datasetPath, 'photolab_dataset.mat');
    if ~isfile(manifestFile)
        error('PhotoLab:noManifest', ...
            'Folder ne sadrži photolab_dataset.mat. Izaberite dataset pripremljen u PhotoLab-u.');
    end
    manifest = load(manifestFile);
    imageSize = manifest.imageSize(1:2);
    channels = manifest.channels;
    if ~(isequal(imageSize, [28 28]) || isequal(imageSize, [32 32])) || ~any(channels == [1 3])
        error('PhotoLab:vaeImageSize', ...
            'Podržane su slike 28x28 i 32x32 sa 1 ili 3 kanala (dataset: %dx%dx%d).', ...
            imageSize(1), imageSize(2), channels);
    end

    trainDir = fullfile(datasetPath, 'training');
    if ~isfolder(trainDir)
        error('PhotoLab:noTraining', 'Dataset nema folder "training".');
    end
    imds = imageDatastore(trainDir, 'IncludeSubfolders', true);
    files = imds.Files;
    if isempty(files)
        error('PhotoLab:noTraining', 'Folder "training" ne sadrži slike.');
    end

    numFiles = numel(files);
    if maxImages > 0 && maxImages < numFiles
        stream = RandStream('twister', 'Seed', seed);
        files = files(sort(randperm(stream, numFiles, maxImages)));
    end
    n = numel(files);

    X = zeros([imageSize channels n], 'single');
    step = max(1, floor(n / 50));
    for k = 1:n
        X(:, :, :, k) = readVaeImage(files{k}, imageSize, channels);
        if ~isempty(progressFcn) && mod(k, step) == 0
            progressFcn(k / n);
        end
    end

    [~, datasetName] = fileparts(datasetPath);
    data = struct('X', X, 'imageSize', imageSize, 'channels', channels, ...
        'classNames', string(manifest.classNames(:)), 'datasetName', datasetName, 'numImages', n);
end
