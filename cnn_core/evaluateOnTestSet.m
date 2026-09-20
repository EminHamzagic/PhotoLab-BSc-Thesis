function [accuracy, yPred, testTime] = evaluateOnTestSet(net, augTest, yTrue, p)
% evaluateOnTestSet Classify the testing/ split and time it
%   accuracy is the fraction of correct predictions, yPred the categorical
%   predictions, testTime the seconds spent classifying.

    timer = tic;
    yPred = classify(net, augTest, 'MiniBatchSize', p.batchSize, ...
        'ExecutionEnvironment', p.executionEnvironment);
    testTime = toc(timer);
    accuracy = mean(yPred == yTrue);
end
