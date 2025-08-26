function f1 = computeF1(yTrue, yPred)
%COMPUTEF1 Computes the F1 score per class
%   yTrue - ground truth labels
%   yPred - predicted labels

    classes = unique(yTrue);   % sve klase
    f1 = zeros(1, numel(classes));

    for i = 1:numel(classes)
        cls = classes(i);
        tp = sum((yPred == cls) & (yTrue == cls));
        fp = sum((yPred == cls) & (yTrue ~= cls));
        fn = sum((yPred ~= cls) & (yTrue == cls));
        
        if tp + fp == 0
            precision = 0;
        else
            precision = tp / (tp + fp);
        end
        
        if tp + fn == 0
            recall = 0;
        else
            recall = tp / (tp + fn);
        end
        
        if precision + recall == 0
            f1(i) = 0;
        else
            f1(i) = 2 * (precision * recall) / (precision + recall);
        end
    end
end
