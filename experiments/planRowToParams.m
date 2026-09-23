function p = planRowToParams(row)
% planRowToParams Training parameter struct (cnn_core format) for one experimentPlan row
%   Starts from defaultTrainingParams and applies the row. Experiment settings:
%   CPU, no plots, MATLAB's console log on, validation once per epoch, early
%   stopping off, so every run does exactly its requested number of epochs.

    p = defaultTrainingParams();
    p.optimizer = char(row.optimizer);
    p.lr = row.learnRate;
    p.batchSize = row.batchSize;
    p.epochs = row.epochs;
    p.weightDecay = row.weightDecay;
    p.augment = logical(row.augmentation);
    p.validationFraction = row.validationSplit;
    p.validationFrequency = 0;          % once per epoch (trainCNNModel)
    p.validationPatience = Inf;         % no early stopping
    p.plots = 'none';
    p.verbose = true;
    p.executionEnvironment = 'cpu';
end
