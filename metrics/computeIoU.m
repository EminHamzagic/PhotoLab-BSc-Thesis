function iou = computeIoU(yTrue, yPred)
%COMPUTEIOU Computes IoU per class
%   yTrue - ground truth labels
%   yPred - predicted labels

classes = unique(yTrue);   % sve klase
iou = zeros(1, numel(classes));

for i = 1:numel(classes)
    cls = classes(i);
    intersection = sum((yPred == cls) & (yTrue == cls));
    union = sum((yPred == cls) | (yTrue == cls));
    
    if union == 0
        iou(i) = 0;
    else
        iou(i) = intersection / union;
    end
end
end
