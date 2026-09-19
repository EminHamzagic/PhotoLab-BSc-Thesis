function loss = vaeReconstructionLoss(Y, X, lossType)
% vaeReconstructionLoss Reconstruction term of the VAE loss, per image
%   Y - decoder output in [0,1], X - target in [0,1] (both H x W x C x B)
%   lossType - 'BCE' (binary cross-entropy) or 'MSE' (sum of squared errors)
%   The loss is summed over pixels and averaged over the batch.

    batchSize = size(X, 4);
    switch upper(lossType)
        case 'BCE'
            tiny = 1e-7;
            loss = -sum(X .* log(Y + tiny) + (1 - X) .* log(1 - Y + tiny), 'all') / batchSize;
        case 'MSE'
            loss = sum((X - Y) .^ 2, 'all') / batchSize;
        otherwise
            error('PhotoLab:vaeLossType', 'Nepoznat rekonstrukcijski gubitak "%s" (BCE ili MSE).', lossType);
    end
end
