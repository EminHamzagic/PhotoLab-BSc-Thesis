function tile = latentManifold(model, gridSize, limit)
% latentManifold Decode a regular grid over [-limit, limit]^2 (latentDim == 2 only)
%   tile = latentManifold(model, gridSize, limit) returns one uint8 tile image.
%   Rows go from z2 = +limit (top) to -limit (bottom), columns from z1 = -limit
%   (left) to +limit (right).

    if nargin < 2, gridSize = 15; end
    if nargin < 3, limit = 3; end
    if model.latentDim ~= 2
        error('PhotoLab:vaeManifold', 'Latentni manifold je dostupan samo za latentDim = 2.');
    end
    [Z1, Z2] = meshgrid(linspace(-limit, limit, gridSize), linspace(limit, -limit, gridSize));
    Z1 = Z1.';   % imtile fills row by row
    Z2 = Z2.';
    imgs = im2uint8(vaeDecodeLatent(model.decoder, [Z1(:)'; Z2(:)']));
    tile = imtile(imgs, 'GridSize', [gridSize gridSize]);
end
