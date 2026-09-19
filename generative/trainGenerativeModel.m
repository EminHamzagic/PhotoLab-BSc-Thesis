function model = trainGenerativeModel(params, datasetPath, progressFcn)
% trainGenerativeModel Train a convolutional VAE with a custom dlnetwork loop
%   model = trainGenerativeModel(params, datasetPath, progressFcn)
%
%   params        struct, see vaeDefaultParams (latentDim, epochs, batchSize,
%                 learnRate, seed, maxImages, beta, reconLossType, numSamples);
%                 missing fields take their defaults
%   datasetPath   PhotoLab dataset folder (photolab_dataset.mat + training/)
%   progressFcn   optional function handle, called
%                   - while loading: info.phase = 'loading', info.fraction
%                   - after every epoch: info.phase = 'epoch', info.epoch,
%                     info.epochs, info.loss/recon/kl (this epoch), info.history
%                     (per-epoch vectors so far), info.sampleGrid (uint8 image of
%                     the fixed-latent samples), info.elapsed
%                 It must return a logical; true stops training after the
%                 current epoch. [] runs without callbacks.
%
%   The returned struct holds every field of the saved VAE file, so
%       save(fileName, '-struct', 'model')
%   writes it. From a script:
%       m = trainGenerativeModel(struct('epochs', 5), 'datasets/MNIST_28x28', []);

    if nargin < 3, progressFcn = []; end
    params = mergeParams(params);

    if ~isempty(progressFcn)
        progressFcn(struct('phase', 'loading', 'fraction', 0));
    end
    data = loadGenerativeDataset(datasetPath, params.maxImages, params.seed, ...
        @(f) notifyLoading(progressFcn, f));

    channels = data.channels;
    if strcmp(params.reconLossType, 'auto')
        if channels == 1
            params.reconLossType = 'BCE';
        else
            params.reconLossType = 'MSE';
        end
    end

    % Reproducible run without disturbing the caller's random stream
    previousRng = rng;
    restoreRng = onCleanup(@() rng(previousRng));
    rng(params.seed, 'twister');

    encoder = vaeEncoderNetwork(data.imageSize, channels, params.latentDim);
    decoder = vaeDecoderNetwork(data.imageSize, channels, params.latentDim);

    % Fixed latent vectors: the same z every epoch, so the sample grids are comparable
    fixedStream = RandStream('twister', 'Seed', params.seed);
    fixedLatent = single(randn(fixedStream, params.latentDim, params.numSamples));

    numImages = data.numImages;
    numEpochs = params.epochs;
    numBatches = ceil(numImages / params.batchSize);

    history = struct('total', zeros(numEpochs, 1), 'recon', zeros(numEpochs, 1), 'kl', zeros(numEpochs, 1));
    sampleGrids = [];
    avgGradE = []; avgSqGradE = [];
    avgGradD = []; avgSqGradD = [];
    iteration = 0;
    epochsDone = 0;

    trainTimer = tic;
    for epoch = 1:numEpochs
        order = randperm(numImages);
        sumTotal = 0; sumRecon = 0; sumKL = 0;

        for b = 1:numBatches
            idx = order((b-1)*params.batchSize+1 : min(b*params.batchSize, numImages));
            X = dlarray(data.X(:, :, :, idx), 'SSCB');
            iteration = iteration + 1;

            [loss, gradE, gradD, reconLoss, klLoss] = dlfeval(@vaeModelLoss, ...
                encoder, decoder, X, params.beta, params.reconLossType);

            [encoder, avgGradE, avgSqGradE] = adamupdate(encoder, gradE, avgGradE, avgSqGradE, ...
                iteration, params.learnRate);
            [decoder, avgGradD, avgSqGradD] = adamupdate(decoder, gradD, avgGradD, avgSqGradD, ...
                iteration, params.learnRate);

            weight = numel(idx);
            sumTotal = sumTotal + double(extractdata(loss)) * weight;
            sumRecon = sumRecon + double(extractdata(reconLoss)) * weight;
            sumKL = sumKL + double(extractdata(klLoss)) * weight;
        end

        history.total(epoch) = sumTotal / numImages;
        history.recon(epoch) = sumRecon / numImages;
        history.kl(epoch) = sumKL / numImages;
        epochsDone = epoch;

        grid = sampleGridImage(im2uint8(vaeDecodeLatent(decoder, fixedLatent)));
        if isempty(sampleGrids)
            sampleGrids = zeros([size(grid) numEpochs], 'uint8');
        end
        sampleGrids(:, :, :, epoch) = grid;

        stop = false;
        if ~isempty(progressFcn)
            info = struct('phase', 'epoch', 'epoch', epoch, 'epochs', numEpochs, ...
                'loss', history.total(epoch), 'recon', history.recon(epoch), 'kl', history.kl(epoch), ...
                'history', struct('total', history.total(1:epoch), 'recon', history.recon(1:epoch), ...
                                  'kl', history.kl(1:epoch)), ...
                'sampleGrid', grid, 'elapsed', toc(trainTimer));
            stop = progressFcn(info);
            stop = ~isempty(stop) && logical(stop(1));
        end
        if stop
            break;
        end
    end
    trainingTime = toc(trainTimer);

    history = struct('total', history.total(1:epochsDone), 'recon', history.recon(1:epochsDone), ...
        'kl', history.kl(1:epochsDone));

    model = struct( ...
        'modelType', 'VAE', ...
        'encoder', encoder, ...
        'decoder', decoder, ...
        'latentDim', params.latentDim, ...
        'imageSize', data.imageSize, ...
        'channels', channels, ...
        'outputRange', '[0,1]', ...
        'datasetName', data.datasetName, ...
        'classNames', data.classNames, ...
        'epochs', numEpochs, ...
        'epochsCompleted', epochsDone, ...
        'batchSize', params.batchSize, ...
        'learnRate', params.learnRate, ...
        'seed', params.seed, ...
        'beta', params.beta, ...
        'maxImages', params.maxImages, ...
        'numSamples', params.numSamples, ...
        'reconLossType', params.reconLossType, ...
        'lossHistory', history, ...
        'trainingTime', trainingTime, ...
        'sampleGrids', sampleGrids(:, :, :, 1:epochsDone));
end

function params = mergeParams(params)
    defaults = vaeDefaultParams();
    for name = fieldnames(defaults)'
        if ~isfield(params, name{1}) || isempty(params.(name{1}))
            params.(name{1}) = defaults.(name{1});
        end
    end
    validateattributes(params.latentDim, {'numeric'}, {'scalar', 'integer', '>=', 1, '<=', 512}, mfilename, 'latentDim');
    validateattributes(params.epochs, {'numeric'}, {'scalar', 'integer', '>=', 1}, mfilename, 'epochs');
    validateattributes(params.batchSize, {'numeric'}, {'scalar', 'integer', '>=', 1}, mfilename, 'batchSize');
    validateattributes(params.learnRate, {'numeric'}, {'scalar', 'positive'}, mfilename, 'learnRate');
    validateattributes(params.seed, {'numeric'}, {'scalar', 'integer', '>=', 0}, mfilename, 'seed');
    validateattributes(params.maxImages, {'numeric'}, {'scalar', 'integer', '>=', 0}, mfilename, 'maxImages');
    validateattributes(params.beta, {'numeric'}, {'scalar', 'nonnegative'}, mfilename, 'beta');
    validateattributes(params.numSamples, {'numeric'}, {'scalar', 'integer', '>=', 1}, mfilename, 'numSamples');
    params.reconLossType = validatestring(char(params.reconLossType), {'auto', 'BCE', 'MSE'});
end

function notifyLoading(progressFcn, fraction)
    if ~isempty(progressFcn)
        progressFcn(struct('phase', 'loading', 'fraction', fraction));
    end
end
