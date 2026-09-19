function recon = reconstructImages(model, X)
% reconstructImages Encode images and decode the posterior mean
%   recon = reconstructImages(model, X), X is single H x W x C x N in [0,1];
%   recon has the same size. The mean mu is used (no sampling noise).

    latentDim = model.latentDim;
    Z = predict(model.encoder, dlarray(single(X), 'SSCB'));
    mu = extractdata(Z(1:latentDim, :));
    recon = vaeDecodeLatent(model.decoder, mu);
end
