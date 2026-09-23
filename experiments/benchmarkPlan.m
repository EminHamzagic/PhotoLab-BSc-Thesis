function estimates = benchmarkPlan(varargin)
% benchmarkPlan Estimate the duration of every run of the plan
%   estimates = benchmarkPlan()
%   estimates = benchmarkPlan('IncludeCIFAR10', true, 'Only', ["R01" "R03"])
%
%   Takes the distinct (architecture, dataset, size, augmentation) combinations of
%   the plan and trains each for 1 epoch on a stratified 5 % and 10 % subset through
%   the same cnn_core code path as runExperiments. From the two timings it fits
%   time = a + b * fraction (a = fixed per-run overhead such as network setup, b =
%   cost of a full epoch), so a run of E epochs is estimated as a + b * E. Prints an
%   estimate per run and in total, so you can decide what to run overnight. Same
%   name-value options as runExperiments.

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

    if isempty(opt.Plan)
        plan = experimentPlan(opt.IncludeCIFAR10, opt.IncludeCIFAR10Aug);
    else
        plan = opt.Plan;
    end
    if ~isempty(opt.Only)
        plan = plan(ismember(plan.runId, string(opt.Only)), :);
    end

    % Distinct combinations; the first plan row of each one is benchmarked
    comboKey = plan.architecture + "|" + plan.dataset + "|" + plan.imageSize(:, 1) + "x" ...
        + plan.imageSize(:, 2) + "|" + string(plan.augmentation);
    [uniqueKeys, firstRow, comboIdx] = unique(comboKey, 'stable');
    numCombos = numel(uniqueKeys);
    fprintf('Benchmarking %d distinct combination(s) on 5%% and 10%% subsets, 1 epoch each\n', numCombos);

    fractions = [0.05 0.10];
    fixedTrain = zeros(numCombos, 1);     % a: overhead per run
    epochTrain = zeros(numCombos, 1);     % b: seconds per full epoch
    fullTest = zeros(numCombos, 1);       % seconds to classify the whole test split
    for c = 1:numCombos
        row = plan(firstRow(c), :);
        fprintf('  [%d/%d] %s\n', c, numCombos, uniqueKeys(c));
        datasetDir = ensureDataset(repoRoot, row.dataset, row.imageSize);
        trainSec = zeros(1, 2);
        testSec = zeros(1, 2);
        for f = 1:2
            p = planRowToParams(row);
            p.epochs = 1;
            p.subsetFraction = fractions(f);
            p.verbose = false;
            rng(row.seed);
            result = trainCNNModel(datasetDir, row.architecture, row.normalization, p, [], []);
            trainSec(f) = result.trainingTime;
            testSec(f) = result.testTime;
        end
        slope = (trainSec(2) - trainSec(1)) / (fractions(2) - fractions(1));
        if slope <= 0                     % timing noise: fall back to plain proportional scaling
            slope = trainSec(2) / fractions(2);
        end
        epochTrain(c) = slope;
        fixedTrain(c) = max(0, trainSec(2) - slope * fractions(2));
        fullTest(c) = testSec(2) / fractions(2);
    end

    estTrain = fixedTrain(comboIdx) + epochTrain(comboIdx) .* plan.epochs;
    estTest = fullTest(comboIdx);
    estTotal = estTrain + estTest;

    estimates = table(plan.runId, plan.experiment, plan.architecture, plan.dataset, ...
        plan.imageSize(:, 1), plan.epochs, plan.augmentation, ...
        estTrain / 60, estTest / 60, estTotal / 60, ...
        'VariableNames', {'runId', 'experiment', 'architecture', 'dataset', 'size', ...
        'epochs', 'augmentation', 'trainMin', 'testMin', 'totalMin'});

    fprintf('\nEstimated durations (fit from 5%% and 10%% subsets):\n');
    disp(estimates);
    fprintf('Total: %.1f h  (%.0f min)\n', sum(estTotal) / 3600, sum(estTotal) / 60);
end
