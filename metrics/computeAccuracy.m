function acc = computeAccuracy(yTrue, yPred)
%COMPUTEACCURACY Computes the overall accuracy of predictions
%   yTrue - ground truth labels
%   yPred - predicted labels

    % Procentualno koliko predikcija je tačno
    acc = mean(yTrue == yPred);
end
