function prepareMNIST(outputDir, h, targetSize)
% prepareMNIST Download MNIST (PNG version) into training/testing folders
%   Creates outputDir/training/0..9 and outputDir/testing/0..9.
%   targetSize = [H W] resizes every image, [] keeps the native 28x28.
%   Shows progress on waitbar if provided.
%
% Example:
%   prepareMNIST(fullfile(pwd,'datasets','MNIST_28x28'), [], [28 28])

    if nargin < 2, h = []; end
    if nargin < 3, targetSize = []; end

    if ~exist(outputDir, 'dir')
        mkdir(outputDir);
    end

    url = 'https://github.com/myleott/mnist_png/raw/master/mnist_png.tar.gz';
    archive = fullfile(outputDir, 'mnist_png.tar.gz');

    % Step 1: Download
    if ~isfile(archive)
        if ~isempty(h), waitbar(0.05, h, 'Downloading MNIST...'); end
        websave(archive, url);
    end

    % Step 2: Extract
    if ~isempty(h), waitbar(0.3, h, 'Extracting files...'); end
    untar(archive, outputDir);
    delete(archive);

    % Step 3: Flatten the mnist_png/ wrapper so training/ and testing/ sit in outputDir
    wrapperDir = fullfile(outputDir, 'mnist_png');
    movefile(fullfile(wrapperDir, 'training'), fullfile(outputDir, 'training'));
    movefile(fullfile(wrapperDir, 'testing'),  fullfile(outputDir, 'testing'));
    rmdir(wrapperDir, 's');

    % Step 4: Resize (archive ships PNGs, so resize after extraction)
    if ~isempty(targetSize) && ~isequal(targetSize(1:2), [28 28])
        if ~isempty(h), waitbar(0.6, h, 'Resizing images...'); end
        resizeImageFolder(outputDir, targetSize, h);
        imageSize = targetSize(1:2);
    else
        imageSize = [28 28];
    end

    writeDatasetManifest(outputDir, 'MNIST', imageSize, 1);

    if ~isempty(h), waitbar(1, h, 'MNIST ready!'); end
end
