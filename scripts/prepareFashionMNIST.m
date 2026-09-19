function prepareFashionMNIST(outputDir, h, targetSize)
% prepareFashionMNIST Download and parse Fashion-MNIST dataset
%   Creates folder structure inside outputDir with training/testing folders.
%   Class folders are named 01_T-shirt ... 10_Ankle-boot so that
%   imageDatastore sorts them in label order.
%   targetSize = [H W] resizes every image, [] keeps the native 28x28.
%   Shows progress on waitbar if provided.
%
% Example:
%   prepareFashionMNIST(fullfile(pwd,'datasets','FashionMNIST_28x28'), h, [28 28])

    if nargin < 2, h = []; end
    if nargin < 3, targetSize = []; end

    if ~exist(outputDir, 'dir')
        mkdir(outputDir);
    end

    % URLs for Fashion-MNIST
    urls = { ...
        'http://fashion-mnist.s3-website.eu-central-1.amazonaws.com/train-images-idx3-ubyte.gz', ...
        'http://fashion-mnist.s3-website.eu-central-1.amazonaws.com/train-labels-idx1-ubyte.gz', ...
        'http://fashion-mnist.s3-website.eu-central-1.amazonaws.com/t10k-images-idx3-ubyte.gz', ...
        'http://fashion-mnist.s3-website.eu-central-1.amazonaws.com/t10k-labels-idx1-ubyte.gz' ...
    };
    files = { ...
        'train-images-idx3-ubyte.gz', ...
        'train-labels-idx1-ubyte.gz', ...
        't10k-images-idx3-ubyte.gz', ...
        't10k-labels-idx1-ubyte.gz' ...
    };

    % Step 1: Download & unzip
    for i = 1:numel(urls)
        localFile = fullfile(outputDir, files{i});
        if ~isfile(localFile)
            if ~isempty(h)
                waitbar((i-1)/numel(urls), h, ['Downloading ' files{i}]);
            end
            websave(localFile, urls{i});
        end
        gunzip(localFile, outputDir);
        delete(localFile); % remove .gz
    end

    % Step 2: Parse IDX files
    if ~isempty(h), waitbar(0.6, h, 'Parsing training set...'); end
    trainImages = loadIDXImages(fullfile(outputDir,'train-images-idx3-ubyte'));
    trainLabels = loadIDXLabels(fullfile(outputDir,'train-labels-idx1-ubyte'));

    if ~isempty(h), waitbar(0.7, h, 'Parsing testing set...'); end
    testImages  = loadIDXImages(fullfile(outputDir,'t10k-images-idx3-ubyte'));
    testLabels  = loadIDXLabels(fullfile(outputDir,'t10k-labels-idx1-ubyte'));

    % Step 3: Save to PNG structure
    if ~isempty(h), waitbar(0.8, h, 'Saving training images...'); end
    saveImages(trainImages, trainLabels, fullfile(outputDir, 'training'), targetSize);
    if ~isempty(h), waitbar(0.95, h, 'Saving testing images...'); end
    saveImages(testImages,  testLabels,  fullfile(outputDir, 'testing'), targetSize);

    % Step 4: Clean raw .ubyte files
    delete(fullfile(outputDir,'train-images-idx3-ubyte'));
    delete(fullfile(outputDir,'train-labels-idx1-ubyte'));
    delete(fullfile(outputDir,'t10k-images-idx3-ubyte'));
    delete(fullfile(outputDir,'t10k-labels-idx1-ubyte'));

    if isempty(targetSize)
        imageSize = [28 28];
    else
        imageSize = targetSize(1:2);
    end
    writeDatasetManifest(outputDir, 'Fashion-MNIST', imageSize, 1);

    if ~isempty(h), waitbar(1, h, 'Fashion-MNIST ready!'); end
end

%% Helper: Load IDX images
function images = loadIDXImages(filename)
    fid = fopen(filename, 'rb');
    magic = fread(fid, 1, 'int32', 0, 'ieee-be');
    if magic ~= 2051, error('Invalid magic number in %s', filename); end
    numImages = fread(fid, 1, 'int32', 0, 'ieee-be');
    numRows   = fread(fid, 1, 'int32', 0, 'ieee-be');
    numCols   = fread(fid, 1, 'int32', 0, 'ieee-be');
    images = fread(fid, inf, 'unsigned char');
    images = reshape(images, numCols, numRows, numImages);
    images = permute(images, [2 1 3]); % reshape to HxWxN
    fclose(fid);
end

%% Helper: Load IDX labels
function labels = loadIDXLabels(filename)
    fid = fopen(filename, 'rb');
    magic = fread(fid, 1, 'int32', 0, 'ieee-be');
    if magic ~= 2049, error('Invalid magic number in %s', filename); end
    numItems = fread(fid, 1, 'int32', 0, 'ieee-be');
    labels = fread(fid, inf, 'unsigned char');
    fclose(fid);
end

%% Helper: Save images into folders by label
% Folder names are zero-padded so string sorting matches label order
% (plain 1..10 would sort as 1, 10, 2, ... and shift every class index).
function saveImages(images, labels, baseDir, targetSize)
    if ~exist(baseDir, 'dir')
        mkdir(baseDir);
    end
    classNames = {'T-shirt', 'Trouser', 'Pullover', 'Dress', 'Coat', ...
                  'Sandal', 'Shirt', 'Sneaker', 'Bag', 'Ankle-boot'};
    classDirs = cell(1, numel(classNames));
    for c = 1:numel(classNames)
        classDirs{c} = fullfile(baseDir, sprintf('%02d_%s', c, classNames{c}));
        if ~exist(classDirs{c}, 'dir')
            mkdir(classDirs{c});
        end
    end
    for i = 1:size(images,3)
        img = uint8(images(:,:,i));
        if ~isempty(targetSize)
            img = imresize(img, targetSize(1:2));
        end
        lbl = labels(i) + 1; % shift 0–9 -> 1–10
        imwrite(img, fullfile(classDirs{lbl}, sprintf('%05d.png', i)));
    end
end
