function precision = computePrecision(yTrue, yPred)
%COMPUTEPRECISION Computes precision per class
%   yTrue - ground truth labels
%   yPred - predicted labels

classes = unique(yTrue);   % sve klase
precision = zeros(1, numel(classes));

for i = 1:numel(classes)
    cls = classes(i);
    tp = sum((yPred == cls) & (yTrue == cls));  % true positives
    fp = sum((yPred == cls) & (yTrue ~= cls));  % false positives
    
    if (tp + fp) == 0
        precision(i) = 0;
    else
        precision(i) = tp / (tp + fp);
    end
end
end
