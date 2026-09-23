function runGenerativeExperiments(varargin)
% runGenerativeExperiments Train the thesis VAE experiments and log them to a CSV
%   runGenerativeExperiments()
%   runGenerativeExperiments('Only', ["G01" "G03"], 'Epochs', 1, 'MaxImages', 2000)
%
%   Four runs: {MNIST, FashionMNIST} x latentDim {2, 16}, beta 1, 20 epochs, seed 42,
%   10 000 training images. Models go to experiments/generative/<runId>.mat (the
%   format loadVaeModel reads), console output to experiments/logs/<runId>.log and
%   one row per run to experiments/generative_results.csv, appended immediately.
%   When experiments/models/R01.mat (MNIST) / R02.mat (FashionMNIST) exist, the
%   generated images are also judged by that classifier: mean confidence, class
%   histogram and simplified Inception Score on 1000 images.
%   Finished runs (status "ok" and model file present) are skipped on a re-run.
%   Epochs and MaxImages exist to allow quick smoke tests.

    parser = inputParser;
    addParameter(parser, 'Only', strings(0, 1));
    addParameter(parser, 'Epochs', 20);
    addParameter(parser, 'MaxImages', 10000);
    parse(parser, varargin{:});
    opt = parser.Results;

    expDir = fileparts(mfilename('fullpath'));
    repoRoot = fileparts(expDir);
    for folder = {'cnn_core', 'scripts', 'metrics', 'generative', 'utils'}
        addpath(fullfile(repoRoot, folder{1}));
    end
    addpath(expDir);

    outDir = fullfile(expDir, 'generative');
    logDir = fullfile(expDir, 'logs');
    for d = {outDir, logDir}
        if ~isfolder(d{1}), mkdir(d{1}); end
    end
    resultsFile = fullfile(expDir, 'generative_results.csv');

    plan = struct( ...
        'runId',     {"G01", "G02", "G03", "G04"}, ...
        'dataset',   {"MNIST", "MNIST", "FashionMNIST", "FashionMNIST"}, ...
        'latentDim', {2, 16, 2, 16}, ...
        'classifier', {"R01", "R01", "R02", "R02"});
    if ~isempty(opt.Only)
        plan = plan(ismember([plan.runId], string(opt.Only)));
    end

    done = completedRunIds(resultsFile, repoRoot);
    numRuns = numel(plan);
    executed = 0;
    busySeconds = 0;
    sessionTimer = tic;

    for k = 1:numRuns
        item = plan(k);
        runId = char(item.runId);
        if ismember(item.runId, done)
            fprintf('[%d/%d] %s already done, skipping\n', k, numRuns, runId);
            continue;
        end

        runTimer = tic;
        modelFile = fullfile('experiments', 'generative', [runId '.mat']);
        logFile = fullfile(logDir, [runId '.log']);
        if isfile(logFile), delete(logFile); end
        diary(logFile);
        stopDiary = onCleanup(@() diary('off'));
        fprintf('[%d/%d] %s: VAE on %s, latentDim %d\n', k, numRuns, runId, item.dataset, item.latentDim);

        params = struct('latentDim', item.latentDim, 'epochs', opt.Epochs, 'beta', 1, ...
            'seed', 42, 'maxImages', opt.MaxImages);
        entry = baseRow(item, params);
        try
            datasetDir = ensureDataset(repoRoot, item.dataset, [28 28]);
            model = trainGenerativeModel(params, datasetDir, @printEpoch);
            save(fullfile(repoRoot, modelFile), '-struct', 'model');

            entry.epochsCompleted = model.epochsCompleted;
            entry.batchSize = model.batchSize;
            entry.learnRate = model.learnRate;
            entry.reconLossType = string(model.reconLossType);
            entry.finalTotalLoss = model.lossHistory.total(end);
            entry.finalReconLoss = model.lossHistory.recon(end);
            entry.finalKLLoss = model.lossHistory.kl(end);
            entry.trainTimeSec = model.trainingTime;
            entry.modelFile = string(strrep(modelFile, '\', '/'));

            classifierFile = fullfile('experiments', 'models', [char(item.classifier) '.mat']);
            if isfile(fullfile(repoRoot, classifierFile))
                loaded = load(fullfile(repoRoot, classifierFile), 'net');
                ev = evaluateWithClassifier(model, loaded.net, 1000, params.seed);
                entry.classifierFile = string(strrep(classifierFile, '\', '/'));
                entry.meanConfidence = ev.meanConfidence;
                entry.inceptionScore = ev.inceptionScore;
                entry.classHistogram = string(strjoin(string(ev.classCounts), '|'));
                fprintf('    classifier %s: confidence %.3f, Inception Score %.2f\n', ...
                    char(item.classifier), ev.meanConfidence, ev.inceptionScore);
            else
                fprintf('    no classifier %s found, skipping classifier evaluation\n', char(item.classifier));
            end
            entry.status = "ok";
        catch ME
            entry.status = "error";
            entry.errorMessage = string(strtrim(regexprep(ME.message, '\s+', ' ')));
            fprintf(2, '    ERROR: %s\n', ME.message);
        end
        clear stopDiary
        diary('off');

        writetable(struct2table(entry), resultsFile, 'WriteMode', 'append', ...
            'WriteVariableNames', ~isfile(resultsFile));

        executed = executed + 1;
        busySeconds = busySeconds + toc(runTimer);
        laterIds = [plan.runId];
        remainingRuns = sum(~ismember(laterIds(k+1:end), done));
        fprintf('    elapsed %s, estimated remaining %s (%d runs left)\n', ...
            formatDuration(toc(sessionTimer)), ...
            formatDuration(busySeconds / executed * remainingRuns), remainingRuns);
    end

    fprintf('Done: %d run(s) executed in %s. Results: %s\n', executed, ...
        formatDuration(toc(sessionTimer)), resultsFile);
end

function stop = printEpoch(info)
    stop = false;
    if strcmp(info.phase, 'epoch')
        fprintf('    epoch %d/%d  loss %.2f  recon %.2f  KL %.2f  (%.0f s)\n', info.epoch, ...
            info.epochs, info.loss, info.recon, info.kl, info.elapsed);
    end
end

function done = completedRunIds(resultsFile, repoRoot)
    done = strings(0, 1);
    if ~isfile(resultsFile), return; end
    opts = detectImportOptions(resultsFile);
    opts = setvartype(opts, 'string');
    T = readtable(resultsFile, opts);
    for i = 1:height(T)
        if T.status(i) == "ok" && ~ismissing(T.modelFile(i)) ...
                && isfile(fullfile(repoRoot, T.modelFile(i)))
            done(end+1, 1) = T.runId(i); %#ok<AGROW>
        end
    end
end

function entry = baseRow(item, params)
    entry = struct( ...
        'runId', item.runId, ...
        'dataset', item.dataset, ...
        'latentDim', item.latentDim, ...
        'beta', params.beta, ...
        'epochs', params.epochs, ...
        'epochsCompleted', NaN, ...
        'batchSize', NaN, ...
        'learnRate', NaN, ...
        'seed', params.seed, ...
        'maxImages', params.maxImages, ...
        'reconLossType', "", ...
        'finalTotalLoss', NaN, ...
        'finalReconLoss', NaN, ...
        'finalKLLoss', NaN, ...
        'trainTimeSec', NaN, ...
        'classifierFile', "", ...
        'meanConfidence', NaN, ...
        'inceptionScore', NaN, ...
        'classHistogram', "", ...
        'modelFile', "", ...
        'status', "", ...
        'errorMessage', "", ...
        'timestamp', string(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss')));
end

function text = formatDuration(seconds)
    text = char(duration(0, 0, seconds, 'Format', 'hh:mm:ss'));
end
