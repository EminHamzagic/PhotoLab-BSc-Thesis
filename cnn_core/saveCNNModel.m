function saveCNNModel(savePath, result, extra)
% saveCNNModel Save a trained classifier in the format PhotoLab's windows read
%   saveCNNModel(savePath, result)
%   saveCNNModel(savePath, result, extra)
%
%   result comes from trainCNNModel. Writes net, accuracy, classNames, inputSize,
%   normalization, architecture, datasetName, yTrue, yPred and testFiles.
%   Every field of the optional struct extra is saved as an additional variable
%   (the experiment runner adds the trainNetwork info struct this way).

    net = result.net;
    accuracy = result.accuracy;
    classNames = result.classNames;
    inputSize = result.inputSize;
    normalization = result.normalization;
    architecture = result.architecture;
    datasetName = result.datasetName;
    yTrue = result.yTrue;
    yPred = result.yPred;
    testFiles = result.testFiles;
    save(savePath, 'net', 'accuracy', 'classNames', 'inputSize', ...
        'normalization', 'architecture', 'datasetName', ...
        'yTrue', 'yPred', 'testFiles');

    if nargin >= 3 && ~isempty(extra)
        save(savePath, '-struct', 'extra', '-append');
    end
end
