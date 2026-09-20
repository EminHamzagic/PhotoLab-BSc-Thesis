function [layers, netInputSize, normalization] = getLayers(archName, inputSize, numClasses, normalization)
% getLayers Layers of a supported classifier architecture (LeNet, AlexNet)
%   Returns the layers, the input size the network needs (the datastore is
%   reconciled to it) and the normalization actually applied.

    inputNorm = getInputNormalization(normalization);
    switch archName
        case "LeNet"
            netInputSize = inputSize;
            layers = [
                imageInputLayer(inputSize, 'Normalization', inputNorm)

                convolution2dLayer(5, 6, 'Padding', 'same')
                batchNormalizationLayer
                reluLayer
                averagePooling2dLayer(2, 'Stride', 2)

                convolution2dLayer(5, 16, 'Padding', 'same')
                batchNormalizationLayer
                reluLayer
                averagePooling2dLayer(2, 'Stride', 2)

                fullyConnectedLayer(120)
                reluLayer
                fullyConnectedLayer(84)
                reluLayer
                fullyConnectedLayer(numClasses)
                softmaxLayer
                classificationLayer];

        case "AlexNet"
            % AlexNet scaled for 28x28 / 32x32 inputs: 5 conv + 3 FC.
            % For larger inputs the first conv strides so the feature
            % maps reaching the FC layers stay CIFAR-sized.
            netInputSize = inputSize;
            stemStride = max(1, round(inputSize(1) / 32));
            layers = [
                imageInputLayer(inputSize, 'Normalization', inputNorm, 'Name', 'input')

                convolution2dLayer(5, 64, 'Stride', stemStride, 'Padding', 'same', 'Name', 'conv1')
                batchNormalizationLayer('Name', 'bn1')
                reluLayer('Name', 'relu1')
                maxPooling2dLayer(2, 'Stride', 2, 'Name', 'pool1')

                convolution2dLayer(5, 192, 'Padding', 'same', 'Name', 'conv2')
                batchNormalizationLayer('Name', 'bn2')
                reluLayer('Name', 'relu2')
                maxPooling2dLayer(2, 'Stride', 2, 'Name', 'pool2')

                convolution2dLayer(3, 384, 'Padding', 'same', 'Name', 'conv3')
                batchNormalizationLayer('Name', 'bn3')
                reluLayer('Name', 'relu3')
                convolution2dLayer(3, 256, 'Padding', 'same', 'Name', 'conv4')
                batchNormalizationLayer('Name', 'bn4')
                reluLayer('Name', 'relu4')
                convolution2dLayer(3, 256, 'Padding', 'same', 'Name', 'conv5')
                batchNormalizationLayer('Name', 'bn5')
                reluLayer('Name', 'relu5')
                maxPooling2dLayer(2, 'Stride', 2, 'Name', 'pool5')

                fullyConnectedLayer(1024, 'Name', 'fc6')
                reluLayer('Name', 'relu6')
                dropoutLayer(0.5, 'Name', 'drop6')
                fullyConnectedLayer(512, 'Name', 'fc7')
                reluLayer('Name', 'relu7')
                dropoutLayer(0.5, 'Name', 'drop7')
                fullyConnectedLayer(numClasses, 'Name', 'fc8')
                softmaxLayer('Name', 'softmax')
                classificationLayer('Name', 'output')];

        otherwise
            error('PhotoLab:unknownArchitecture', 'Arhitektura "%s" nije podržana.', archName);
    end
end
