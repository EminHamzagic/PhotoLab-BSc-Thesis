function runExperiments(varargin)
% runExperiments Run the thesis experiment plan unattended on the CPU
%   runExperiments()
%   runExperiments('IncludeCIFAR10', true, 'IncludeCIFAR10Aug', true, 'Only', ["R07" "R08"])
%
%   Name-value options:
%     IncludeCIFAR10     append R16-R17 (default false)
%     IncludeCIFAR10Aug  also append R18, AlexNet + augmentation (default false)
%     Only               string array of runIds to run (default: all)
%     Plan               a table in experimentPlan format instead of the built-in plan
%
%   Every run goes through cnn_core/trainCNNModel, the code path of TrainingCNN,
%   so the saved models are "trained in PhotoLab". Per run:
%     experiments/models/<runId>.mat   model file (TrainingCNN fields + info)
%     experiments/logs/<runId>.log     console output
%     experiments/results.csv          one row, appended immediately
%   A runId is skipped when results.csv has it with status "ok" and its model
%   file exists, so an interrupted run can simply be started again.

    parser = inputParser;
    addParameter(parser, 'IncludeCIFAR10', false);
    addParameter(parser, 'IncludeCIFAR10Aug', false);
    addParameter(parser, 'Only', strings(0, 1));
    addParameter(parser, 'Plan', []);
    parse(parser, varargin{:});
    opt = parser.Results;

    expDir = fileparts(mfilename('fullpath'));
    repoRoot = fileparts(expDir);
    for folder = {'cnn_core', 'scripts', 'metrics', 'generative', 'utils'}
        addpath(fullfile(repoRoot, folder{1}));
    end
    addpath(expDir);

    modelDir = fullfile(expDir, 'models');
    logDir = fullfile(expDir, 'logs');
    for d = {modelDir, logDir}
        if ~isfolder(d{1}), mkdir(d{1}); end
    end
    resultsFile = fullfile(expDir, 'results.csv');

    if isempty(opt.Plan)
        plan = experimentPlan(opt.IncludeCIFAR10, opt.IncludeCIFAR10Aug);
    else
        plan = opt.Plan;
    end
    if ~isempty(opt.Only)
        plan = plan(ismember(plan.runId, string(opt.Only)), :);
    end

    done = completedRunIds(resultsFile, repoRoot);
    numRuns = height(plan);
    executed = 0;
    busySeconds = 0;
    sessionTimer = tic;

    for k = 1:numRuns
        row = plan(k, :);
        runId = char(row.runId);
        if ismember(row.runId, done)
            fprintf('[%d/%d] %s already done, skipping\n', k, numRuns, runId);
            continue;
        end

        runTimer = tic;
        modelFile = fullfile('experiments', 'models', [runId '.mat']);
        logFile = fullfile(logDir, [runId '.log']);
        if isfile(logFile), delete(logFile); end
        diary(logFile);
        stopDiary = onCleanup(@() diary('off'));
        fprintf('[%d/%d] %s: %s %s %dx%d %s lr=%g %d epochs, aug=%d\n', k, numRuns, runId, ...
            row.architecture, row.dataset, row.imageSize(1), row.imageSize(2), ...
            row.optimizer, row.learnRate, row.epochs, row.augmentation);

        try
            datasetDir = ensureDataset(repoRoot, row.dataset, row.imageSize);
            p = planRowToParams(row);
            rng(row.seed);
            result = trainCNNModel(datasetDir, row.architecture, row.normalization, p, [], []);
            saveCNNModel(fullfile(repoRoot, modelFile), result, struct('info', result.info));
            entry = okRow(row, result, modelFile);
            fprintf('    test accuracy %.2f%%, train %.0f s, test %.1f s\n', ...
                result.accuracy * 100, result.trainingTime, result.testTime);
        catch ME
            entry = errorRow(row, ME);
            fprintf(2, '    ERROR: %s\n', ME.message);
        end
        clear stopDiary
        diary('off');

        appendRow(resultsFile, entry);

        executed = executed + 1;
        busySeconds = busySeconds + toc(runTimer);
        remainingRuns = sum(~ismember(plan.runId(k+1:end), done));
        fprintf('    elapsed %s, estimated remaining %s (%d runs left)\n', ...
            formatDuration(toc(sessionTimer)), ...
            formatDuration(busySeconds / executed * remainingRuns), remainingRuns);
    end

    fprintf('Done: %d run(s) executed in %s. Results: %s\n', executed, ...
        formatDuration(toc(sessionTimer)), resultsFile);
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

function entry = baseRow(row)
    entry = struct( ...
        'runId', row.runId, ...
        'experiment', row.experiment, ...
        'architecture', row.architecture, ...
        'dataset', row.dataset, ...
        'inputSize', "", ...
        'normalization', row.normalization, ...
        'optimizer', row.optimizer, ...
        'learnRate', row.learnRate, ...
        'batchSize', row.batchSize, ...
        'epochs', row.epochs, ...
        'augmentation', row.augmentation, ...
        'seed', row.seed, ...
        'finalValAccuracy', NaN, ...
        'bestValAccuracy', NaN, ...
        'testAccuracy', NaN, ...
        'macroF1', NaN, ...
        'trainTimeSec', NaN, ...
        'testTimeSec', NaN, ...
        'numLearnables', NaN, ...
        'modelFile', "", ...
        'status', "", ...
        'errorMessage', "", ...
        'timestamp', string(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss')));
end

function entry = okRow(row, result, modelFile)
    entry = baseRow(row);
    entry.inputSize = string(sprintf('%dx%dx%d', result.inputSize));
    valAcc = result.info.ValidationAccuracy;
    valAcc = valAcc(~isnan(valAcc));
    entry.finalValAccuracy = result.validationAccuracy;
    if ~isempty(valAcc)
        entry.bestValAccuracy = max(valAcc) / 100;
    end
    entry.testAccuracy = result.accuracy;
    entry.macroF1 = mean(computeF1(result.yTrue, result.yPred));
    entry.trainTimeSec = result.trainingTime;
    entry.testTimeSec = result.testTime;
    entry.numLearnables = result.numLearnables;
    entry.modelFile = string(strrep(modelFile, '\', '/'));
    entry.status = "ok";
end

function entry = errorRow(row, ME)
    entry = baseRow(row);
    entry.inputSize = string(sprintf('%dx%d', row.imageSize));
    entry.status = "error";
    entry.errorMessage = string(strtrim(regexprep(ME.message, '\s+', ' ')));
end

function appendRow(resultsFile, entry)
    writetable(struct2table(entry), resultsFile, 'WriteMode', 'append', ...
        'WriteVariableNames', ~isfile(resultsFile));
end

function text = formatDuration(seconds)
    text = char(duration(0, 0, seconds, 'Format', 'hh:mm:ss'));
end
