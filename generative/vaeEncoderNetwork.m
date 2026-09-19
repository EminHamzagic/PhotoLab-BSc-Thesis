function net = vaeEncoderNetwork(imageSize, channels, latentDim)
% vaeEncoderNetwork Convolutional VAE encoder as an initialised dlnetwork
%   net = vaeEncoderNetwork([H W], C, latentDim)
%
%   Two stride-2 convolutions followed by one fully connected layer. The
%   output has 2*latentDim rows: the first latentDim are mu, the rest logVar.
%   Supported inputs: 28x28 and 32x32 images with 1 or 3 channels.

    checkVaeImageSize(imageSize, channels);

    layers = [
        imageInputLayer([imageSize(1:2) channels], 'Normalization', 'none', 'Name', 'input')

        convolution2dLayer(3, 32, 'Stride', 2, 'Padding', 'same', 'Name', 'conv1')
        reluLayer('Name', 'relu1')

        convolution2dLayer(3, 64, 'Stride', 2, 'Padding', 'same', 'Name', 'conv2')
        reluLayer('Name', 'relu2')

        fullyConnectedLayer(2 * latentDim, 'Name', 'fc_mu_logvar')];

    net = dlnetwork(layers);
end

function checkVaeImageSize(imageSize, channels)
    if ~(isequal(imageSize(1:2), [28 28]) || isequal(imageSize(1:2), [32 32])) ...
            || ~any(channels == [1 3])
        error('PhotoLab:vaeImageSize', ...
            'Podržane su slike 28x28 i 32x32 sa 1 ili 3 kanala (dobijeno %dx%dx%d).', ...
            imageSize(1), imageSize(2), channels);
    end
end
