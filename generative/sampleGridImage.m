function img = sampleGridImage(imgs, gridSize)
% sampleGridImage Tile images (H x W x C x N, uint8) into one image for display
%   img = sampleGridImage(imgs)                near-square grid
%   img = sampleGridImage(imgs, [rows cols])   images fill the grid row by row

    n = size(imgs, 4);
    if nargin < 2 || isempty(gridSize)
        cols = ceil(sqrt(n));
        gridSize = [ceil(n / cols) cols];
    end
    img = imtile(imgs, 'GridSize', gridSize, 'BorderSize', 1, 'BackgroundColor', 'white');
end
