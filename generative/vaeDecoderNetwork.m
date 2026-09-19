function net = vaeDecoderNetwork(imageSize, channels, latentDim)
% vaeDecoderNetwork Transposed-convolution VAE decoder as an initialised dlnetwork
%   net = vaeDecoderNetwork([H W], C, latentDim)
%
%   Input is a 1x1xlatentDim "image" (format SSCB). A transposed convolution
%   with a kernel of the feature-map size acts as the linear projection plus
%   reshape, then two stride-2 transposed convolutions upsample to H x W. The
%   sigmoid output lies in [0,1]. Only built-in layers are used, so a saved
%   decoder loads without any custom class on the path.

    if ~(isequal(imageSize(1:2), [28 28]) || isequal(imageSize(1:2), [32 32])) ...
            || ~any(channels == [1 3])
        error('PhotoLab:vaeImageSize', ...
            'Podržane su slike 28x28 i 32x32 sa 1 ili 3 kanala (dobijeno %dx%dx%d).', ...
            imageSize(1), imageSize(2), channels);
    end
    baseSize = imageSize(1) / 4;   % 7 for 28x28, 8 for 32x32

    layers = [
        imageInputLayer([1 1 latentDim], 'Normalization', 'none', 'Name', 'latent')

        transposedConv2dLayer(baseSize, 64, 'Name', 'project')
        reluLayer('Name', 'relu0')

        transposedConv2dLayer(3, 64, 'Stride', 2, 'Cropping', 'same', 'Name', 'tconv1')
        reluLayer('Name', 'relu1')

        transposedConv2dLayer(3, 32, 'Stride', 2, 'Cropping', 'same', 'Name', 'tconv2')
        reluLayer('Name', 'relu2')

        transposedConv2dLayer(3, channels, 'Cropping', 'same', 'Name', 'tconv3')
        sigmoidLayer('Name', 'output')];

    net = dlnetwork(layers);
end
