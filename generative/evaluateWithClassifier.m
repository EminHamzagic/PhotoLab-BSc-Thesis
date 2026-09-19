function result = evaluateWithClassifier(model, net, n, seed)
% evaluateWithClassifier Judge generated images with a PhotoLab-trained classifier
%   result = evaluateWithClassifier(model, net, n, seed)
%
%   Generates n images with the VAE, feeds them to the classifier the way the
%   training images were fed (uint8 on the 0-255 scale, augmentedImageDatastore
%   to the net's input size and channels; the input layer normalizes itself)
%   and returns a struct with:
%     classNames      classifier classes
%     classCounts     how many images were predicted as each class
%     meanConfidence  mean of the max softmax score
%     inceptionScore  exp( mean_x KL( p(y|x) || p(y) ) )
%     scores, predicted, numImages

    if nargin < 3, n = 1000; end
    if nargin < 4, seed = 1; end

    imgs = generateImages(model, n, seed);             % uint8, 0-255

    inputSize = net.Layers(1).InputSize;
    if inputSize(3) == 3 && size(imgs, 3) == 1
        colorPrep = 'gray2rgb';
    elseif inputSize(3) == 1 && size(imgs, 3) == 3
        colorPrep = 'rgb2gray';
    else
        colorPrep = 'none';
    end
    augds = augmentedImageDatastore(inputSize(1:2), imgs, 'ColorPreprocessing', colorPrep);
    [predicted, scores] = classify(net, augds, 'MiniBatchSize', 128);

    scores = double(scores);
    marginal = mean(scores, 1);                         % p(y)
    klPerImage = sum(scores .* (log(scores + eps) - log(marginal + eps)), 2);

    classNames = string(net.Layers(end).Classes);
    result = struct( ...
        'classNames', classNames(:), ...
        'classCounts', countcats(categorical(string(predicted), classNames))', ...
        'meanConfidence', mean(max(scores, [], 2)), ...
        'inceptionScore', exp(mean(klPerImage)), ...
        'scores', scores, ...
        'predicted', predicted, ...
        'numImages', n);
end
