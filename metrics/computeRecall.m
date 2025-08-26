function recall = computeRecall(yTrue, yPred)
%COMPUTERECALL Computes recall per class
%   yTrue - ground truth labels
%   yPred - predicted labels

classes = unique(yTrue);   % sve klase
recall = zeros(1, numel(classes));

for i = 1:numel(classes)
    cls = classes(i);
    tp = sum((yPred == cls) & (yTrue == cls));  % true positives
    fn = sum((yPred ~= cls) & (yTrue == cls));  % false negatives
    
    if (tp + fn) == 0
        recall(i) = 0;
    else
        recall(i) = tp / (tp + fn);
    end
end
end
