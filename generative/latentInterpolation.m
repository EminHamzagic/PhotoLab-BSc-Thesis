function [imgs, z] = latentInterpolation(model, numSteps, seed)
% latentInterpolation Decode a straight line between two random latent points
%   [imgs, z] = latentInterpolation(model, numSteps, seed)
%   The end points are drawn from N(0, I); z is latentDim x numSteps and imgs
%   the decoded uint8 H x W x C x numSteps images (first = start, last = end).

    if nargin < 3, seed = 1; end
    stream = RandStream('twister', 'Seed', seed);
    ends = single(randn(stream, model.latentDim, 2));
    t = linspace(0, 1, numSteps);
    z = ends(:, 1) * (1 - t) + ends(:, 2) * t;
    imgs = im2uint8(vaeDecodeLatent(model.decoder, z));
end
