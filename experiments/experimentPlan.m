function plan = experimentPlan(includeCIFAR10, includeCIFAR10Aug)
% experimentPlan The thesis experiment plan as an editable table
%   plan = experimentPlan()
%   plan = experimentPlan(includeCIFAR10, includeCIFAR10Aug)
%
%   Every run starts from the baseline below and changes only what its row in
%   the list lists. includeCIFAR10 appends R16-R17 (20 epochs); R18 (AlexNet +
%   augmentation on CIFAR-10, expensive) additionally needs includeCIFAR10Aug.
%
%   dataset is the folder key used by DatasetManagerApp: 'MNIST', 'FashionMNIST',
%   'CIFAR10' -> datasets/<key>_<W>x<H>. imageSize is [H W].

    if nargin < 1, includeCIFAR10 = false; end
    if nargin < 2, includeCIFAR10Aug = false; end

    base = struct( ...
        'runId', "", 'experiment', "", 'architecture', "LeNet", 'dataset', "MNIST", ...
        'imageSize', [28 28], 'normalization', "MinMax", 'optimizer', "adam", ...
        'learnRate', 1e-3, 'batchSize', 128, 'epochs', 10, 'augmentation', false, ...
        'seed', 42, 'validationSplit', 0.1, 'weightDecay', 5e-4);

    rows = {
        % runId   exp   overrides
        'R01', 'E1', {'architecture', "LeNet",   'dataset', "MNIST"}
        'R02', 'E1', {'architecture', "LeNet",   'dataset', "FashionMNIST"}
        'R03', 'E1', {'architecture', "AlexNet", 'dataset', "MNIST"}
        'R04', 'E1', {'architecture', "AlexNet", 'dataset', "FashionMNIST"}
        'R05', 'E2', {'dataset', "MNIST", 'imageSize', [32 32]}
        'R06', 'E2', {'dataset', "MNIST", 'imageSize', [64 64]}
        'R07', 'E3', {'dataset', "FashionMNIST", 'optimizer', "sgdm",    'learnRate', 1e-2}
        'R08', 'E3', {'dataset', "FashionMNIST", 'optimizer', "sgdm",    'learnRate', 1e-3}
        'R09', 'E3', {'dataset', "FashionMNIST", 'optimizer', "rmsprop", 'learnRate', 1e-3}
        'R10', 'E3', {'dataset', "FashionMNIST", 'optimizer', "rmsprop", 'learnRate', 1e-4}
        'R11', 'E3', {'dataset', "FashionMNIST", 'optimizer', "adam",    'learnRate', 1e-4}
        'R12', 'E4', {'dataset', "FashionMNIST", 'normalization', "None"}
        'R13', 'E4', {'dataset', "FashionMNIST", 'normalization', "Mean-Std"}
        'R14', 'E5', {'dataset', "MNIST",        'augmentation', true}
        'R15', 'E5', {'dataset', "FashionMNIST", 'augmentation', true}};

    if includeCIFAR10
        cifar = {'dataset', "CIFAR10", 'imageSize', [32 32], 'epochs', 20};
        rows(end+1, :) = {'R16', 'E1', [cifar, {'architecture', "LeNet"}]};
        rows(end+1, :) = {'R17', 'E1', [cifar, {'architecture', "AlexNet"}]};
        if includeCIFAR10Aug
            rows(end+1, :) = {'R18', 'E5', [cifar, {'architecture', "AlexNet", 'augmentation', true}]};
        end
    end

    s = repmat(base, size(rows, 1), 1);
    for k = 1:size(rows, 1)
        s(k).runId = string(rows{k, 1});
        s(k).experiment = string(rows{k, 2});
        overrides = rows{k, 3};
        for j = 1:2:numel(overrides)
            s(k).(overrides{j}) = overrides{j+1};
        end
    end
    plan = struct2table(s);
end
