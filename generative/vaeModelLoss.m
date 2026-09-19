function [loss, gradE, gradD, reconLoss, klLoss] = vaeModelLoss(encoder, decoder, X, beta, lossType)
% vaeModelLoss VAE loss and gradients, to be called through dlfeval
%   loss = reconstruction loss + beta * KL(q(z|x) || N(0, I))
%   X is a dlarray with format SSCB and values in [0,1].

    Z = forward(encoder, X);                       % (2*latentDim) x B, format CB
    latentDim = size(Z, 1) / 2;
    batchSize = size(Z, 2);
    mu = Z(1:latentDim, :);
    logVar = Z(latentDim+1:end, :);

    z = vaeSampleLatent(mu, logVar);
    zImage = dlarray(reshape(stripdims(z), 1, 1, latentDim, batchSize), 'SSCB');
    Y = forward(decoder, zImage);

    reconLoss = vaeReconstructionLoss(Y, X, lossType);
    klLoss = -0.5 * sum(1 + logVar - mu .^ 2 - exp(logVar), 'all') / batchSize;
    loss = reconLoss + beta * klLoss;

    [gradE, gradD] = dlgradient(loss, encoder.Learnables, decoder.Learnables);
end
