function prepareCIFAR10(outputDir, h)
% prepareCIFAR10 Download and parse CIFAR-10 (MATLAB version)
%   Creates folder structure inside outputDir with training/testing folders.
%   Shows progress on waitbar if provided.
%
% Example:
%   prepareCIFAR10(fullfile(pwd,'datasets','CIFAR10'), h)

    if nargin < 2, h = []; end

    if ~exist(outputDir, 'dir')
        mkdir(outputDir);
    end

    url = 'https://www.cs.toronto.edu/~kriz/cifar-10-matlab.tar.gz';
    tarFile = fullfile(outputDir, 'cifar-10-matlab.tar.gz');

    % Step 1: Download
    if ~isfile(tarFile)
        if ~isempty(h), waitbar(0.05, h, 'Downloading CIFAR-10...'); end
        websave(tarFile, url);
    end

    % Step 2: Extract
    if ~isempty(h), waitbar(0.2, h, 'Extracting files...'); end
    untar(tarFile, outputDir);
    delete(tarFile);

    % The extracted folder is "cifar-10-batches-mat"
    cifarDir = fullfile(outputDir, 'cifar-10-batches-mat');

    % Step 3: Load meta (label names)
    meta = load(fullfile(cifarDir, 'batches.meta.mat'));
    labelNames = meta.label_names; % 10 class names

    % Step 4: Training batches
    if ~isempty(h), waitbar(0.3, h, 'Parsing training batches...'); end
    for b = 1:5
        batch = load(fullfile(cifarDir, sprintf('data_batch_%d.mat', b)));
        saveImages(batch.data, batch.labels, ...
            fullfile(outputDir, 'training'), labelNames, h, (0.3+b*0.1));
    end

    % Step 5: Test batch
    if ~isempty(h), waitbar(0.85, h, 'Parsing test batch...'); end
    testBatch = load(fullfile(cifarDir, 'test_batch.mat'));
    saveImages(testBatch.data, testBatch.labels, ...
        fullfile(outputDir, 'testing'), labelNames, h, 0.95);

    % Step 6: Cleanup extracted MAT files
    rmdir(cifarDir, 's');

    if ~isempty(h), waitbar(1, h, 'CIFAR-10 ready!'); end
end

%% Helper: Save images into folders by label
function saveImages(data, labels, baseDir, labelNames, h, progressPoint)
    if ~exist(baseDir, 'dir')
        mkdir(baseDir);
    end
    numClasses = numel(labelNames);
    for c = 1:numClasses
        classDir = fullfile(baseDir, sprintf('%d_%s', c, labelNames{c}));
        if ~exist(classDir, 'dir')
            mkdir(classDir);
        end
    end

    numImages = size(data,1);
    for i = 1:numImages
        % CIFAR-10: each row is 3072 = 1024R + 1024G + 1024B
        r = reshape(data(i,1:1024), [32,32])';
        g = reshape(data(i,1025:2048), [32,32])';
        b = reshape(data(i,2049:3072), [32,32])';
        img = cat(3, r, g, b);

        lbl = labels(i) + 1; % shift 0–9 -> 1–10
        imwrite(img, fullfile(baseDir, sprintf('%d_%s', lbl, labelNames{lbl}), ...
            sprintf('%05d.png', i)));
    end

    if nargin >= 6 && ~isempty(h)
        waitbar(progressPoint, h);
    end
end