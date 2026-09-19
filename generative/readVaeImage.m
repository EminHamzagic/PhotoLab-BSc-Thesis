function img = readVaeImage(file, imageSize, channels)
% readVaeImage Read one dataset image as single H x W x C in [0,1]
%   Converts between grayscale and RGB when the file has another channel count
%   than the model expects, and errors if the size does not match imageSize.

    img = imread(file);
    if size(img, 3) == 1 && channels == 3
        img = repmat(img, 1, 1, 3);
    elseif size(img, 3) == 3 && channels == 1
        img = rgb2gray(img);
    end
    if ~isequal(size(img, 1:2), imageSize(1:2))
        error('PhotoLab:imageSize', 'Slika %s nema veličinu %dx%d.', file, imageSize(1), imageSize(2));
    end
    img = single(img) / 255;
end
