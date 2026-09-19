function imgs = generateImages(model, n, seed)
% generateImages Sample n images from a trained VAE
%   imgs = generateImages(model, n, seed) returns uint8 H x W x C x n.
%   z ~ N(0, I) is drawn from its own RandStream, so the global RNG is untouched
%   and the same seed always gives the same images.

    if nargin < 3, seed = 1; end
    stream = RandStream('twister', 'Seed', seed);
    z = single(randn(stream, model.latentDim, n));
    imgs = im2uint8(vaeDecodeLatent(model.decoder, z));
end
