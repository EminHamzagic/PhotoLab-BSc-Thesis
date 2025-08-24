function convertIdxToImages(datasetPath)
    % Load MNIST/Fashion-MNIST data from .idx files
    trainImages = loadMNISTImages(fullfile(datasetPath, 'train-images-idx3-ubyte'));
    trainLabels = loadMNISTLabels(fullfile(datasetPath, 'train-labels-idx1-ubyte'));
    testImages = loadMNISTImages(fullfile(datasetPath, 't10k-images-idx3-ubyte'));
    testLabels = loadMNISTLabels(fullfile(datasetPath, 't10k-labels-idx1-ubyte'));
    
    % Create directories for training and testing images
    trainDir = fullfile(datasetPath, 'train');
    testDir = fullfile(datasetPath, 'test');
    mkdir(trainDir);
    mkdir(testDir);
    
    % Save images as PNGs in class-specific subfolders
    saveImages(trainImages, trainLabels, trainDir);
    saveImages(testImages, testLabels, testDir);
    
    % Delete raw .idx files (optional)
    delete(fullfile(datasetPath, '*.idx'));
end

function saveImages(images, labels, outputDir)
    % Create subfolders for each class
    for i = 0:9
        mkdir(fullfile(outputDir, num2str(i)));
    end
    
    % Save images to appropriate folders
    for i = 1:size(images, 2)
        img = reshape(images(:, i), 28, 28);
        label = num2str(labels(i));
        imwrite(img, fullfile(outputDir, label, sprintf('%05d.png', i)));
    end
end

% Helper functions to read .idx files (place these in a separate file)
function images = loadMNISTImages(filename)
    [fileID, ~] = gunzip(filename);
    fileID = fopen(fileID{1}, 'r');
    fread(fileID, 4, 'uint8'); % Skip header
    images = fread(fileID, Inf, 'uint8');
    fclose(fileID);
    images = reshape(images, 28, 28, []);
end

function labels = loadMNISTLabels(filename)
    [fileID, ~] = gunzip(filename);
    fileID = fopen(fileID{1}, 'r');
    fread(fileID, 2, 'uint8'); % Skip header
    labels = fread(fileID, Inf, 'uint8');
    fclose(fileID);
end