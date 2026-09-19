function resizeImageFolder(rootDir, targetSize, h)
% resizeImageFolder Resize every image under rootDir/training and rootDir/testing in place
%   targetSize = [H W]. Shows progress on waitbar h if provided.
%
% Example:
%   resizeImageFolder(fullfile(pwd,'datasets','MNIST_32x32'), [32 32])

    if nargin < 3, h = []; end
    if isempty(targetSize), return; end
    targetSize = targetSize(1:2);

    files = [];
    for split = ["training", "testing"]
        splitDir = fullfile(rootDir, split);
        if isfolder(splitDir)
            files = [files; dir(fullfile(splitDir, '**', '*.png'))]; %#ok<AGROW>
        end
    end

    numFiles = numel(files);
    for i = 1:numFiles
        f = fullfile(files(i).folder, files(i).name);
        img = imread(f);
        if ~isequal(size(img, [1 2]), targetSize)
            imwrite(imresize(img, targetSize), f);
        end
        if ~isempty(h) && mod(i, 1000) == 0
            waitbar(0.6 + 0.35 * i / numFiles, h, sprintf('Promjena veličine slika (%d/%d)...', i, numFiles));
        end
    end
end
