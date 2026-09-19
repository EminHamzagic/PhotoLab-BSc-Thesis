function imgs = vaeDecodeLatent(decoder, z)
% vaeDecodeLatent Decode latent vectors into images in [0,1]
%   imgs = vaeDecodeLatent(decoder, z), z is latentDim x N (numeric).
%   Returns a single H x W x C x N array. Decodes in chunks to keep memory low.

    z = single(z);
    latentDim = size(z, 1);
    n = size(z, 2);
    chunk = 200;
    parts = cell(1, ceil(n / chunk));
    for k = 1:numel(parts)
        idx = (k-1)*chunk+1 : min(k*chunk, n);
        zImage = dlarray(reshape(z(:, idx), 1, 1, latentDim, numel(idx)), 'SSCB');
        parts{k} = extractdata(predict(decoder, zImage));
    end
    imgs = cat(4, parts{:});
end
