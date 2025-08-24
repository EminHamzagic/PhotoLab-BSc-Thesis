function prepareCIFAR100(outputDir, h)
% prepareCIFAR100 Download and parse CIFAR-100 (MATLAB version)
%   Creates folder structure inside outputDir with training/testing folders.
%   Uses fine labels (100 classes). Shows progress on waitbar if provided.
%
% Example:
%   prepareCIFAR100(fullfile(pwd,'datasets','CIFAR100'), h)

    if nargin < 2, h = []; end

    if ~exist(outputDir, 'dir')
        mkdir(outputDir);
    end

    url = 'https://www.cs.toronto.edu/~kriz/cifar-100-matlab.tar.gz';
    tarFile = fullfile(outputDir, 'cifar-100-matlab.tar.gz');

    % Step 1: Download
    if ~isfile(tarFile)
        if ~isempty(h), waitbar(0.05, h, 'Downloading CIFAR-100...'); end
        websave(tarFile, url);
    end

    % Step 2: Extract
    if ~isempty(h), waitbar(0.2, h, 'Extracting files...'); end
    untar(tarFile, outputDir);
    delete(tarFile);

    % Extracted folder
    cifarDir = fullfile(outputDir, 'cifar-100-matlab');

    % Step 3: Load meta (label names)
    meta = load(fullfile(cifarDir, 'meta.mat'));
    labelNames = meta.fine_label_names; % 100 fine labels (cell array)

    % Step 4: Training set
    if ~isempty(h), waitbar(0.3, h, 'Parsing training set...'); end
    trainData = load(fullfile(cifarDir, 'train.mat'));
    saveImages(trainData.data, trainData.fine_labels, ...
        fullfile(outputDir, 'training'), labelNames, h, 0.7);

    % Step 5: Test set
    if ~isempty(h), waitbar(0.8, h, 'Parsing test set...'); end
    testData = load(fullfile(cifarDir, 'test.mat'));
    saveImages(testData.data, testData.fine_labels, ...
        fullfile(outputDir, 'testing'), labelNames, h, 0.95);

    % Step 6: Cleanup extracted MAT files
    rmdir(cifarDir, 's');

    if ~isempty(h), waitbar(1, h, 'CIFAR-100 ready!'); end
end

%% Helper: Save images into folders by label
function saveImages(data, labels, baseDir, labelNames, h, progressPoint)
    if ~exist(baseDir, 'dir')
        mkdir(baseDir);
    end
    numClasses = numel(labelNames);
    for c = 1:numClasses
        classDir = fullfile(baseDir, sprintf('%03d_%s', c, labelNames{c}));
        if ~exist(classDir, 'dir')
            mkdir(classDir);
        end
    end

    numImages = size(data,1);
    for i = 1:numImages
        % CIFAR-100: 3072 = 1024R + 1024G + 1024B
        r = reshape(data(i,1:1024), [32,32])';
        g = reshape(data(i,1025:2048), [32,32])';
        b = reshape(data(i,2049:3072), [32,32])';
        img = cat(3, r, g, b);

        lbl = labels(i) + 1; % shift 0–99 -> 1–100
        imwrite(img, fullfile(baseDir, sprintf('%03d_%s', lbl, labelNames{lbl}), ...
            sprintf('%05d.png', i)));
    end

    if nargin >= 6 && ~isempty(h)
        waitbar(progressPoint, h);
    end
end
