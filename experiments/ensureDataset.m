function datasetDir = ensureDataset(repoRoot, key, imageSize)
% ensureDataset Path of datasets/<key>_<W>x<H>, downloading it first when missing
%   datasetDir = ensureDataset(repoRoot, key, imageSize)
%
%   key is 'MNIST', 'FashionMNIST' or 'CIFAR10'; imageSize is [H W]. A dataset
%   counts as ready when photolab_dataset.mat exists (it is written last). The
%   download mirrors DatasetManagerApp.downloadDataset: native size is written
%   as-is (prepareSize = []), anything else is resized while writing, and a
%   failed download is removed again.

    key = char(key);
    switch key
        case 'MNIST',         prepareFcn = @prepareMNIST;        nativeSize = [28 28];
        case 'FashionMNIST',  prepareFcn = @prepareFashionMNIST; nativeSize = [28 28];
        case 'CIFAR10',       prepareFcn = @prepareCIFAR10;      nativeSize = [32 32];
        otherwise
            error('PhotoLab:unknownDataset', 'Unknown dataset key "%s".', key);
    end

    datasetDir = fullfile(repoRoot, 'datasets', sprintf('%s_%dx%d', key, imageSize(2), imageSize(1)));
    if isfile(fullfile(datasetDir, 'photolab_dataset.mat'))
        return;
    end

    if isequal(imageSize, nativeSize)
        prepareSize = [];
    else
        prepareSize = imageSize;
    end

    fprintf('Preparing %s ...\n', datasetDir);
    if isfolder(datasetDir)
        rmdir(datasetDir, 's');     % leftover from an interrupted download
    end
    mkdir(datasetDir);
    try
        prepareFcn(datasetDir, [], prepareSize);
    catch ME
        if isfolder(datasetDir)
            rmdir(datasetDir, 's');
        end
        rethrow(ME);
    end
end
