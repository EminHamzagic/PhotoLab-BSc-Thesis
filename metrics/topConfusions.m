function T = topConfusions(yTrue, yPred, n)
% topConfusions The n most frequent misclassifications as a table
%   T = topConfusions(yTrue, yPred, n) returns the n largest off-diagonal
%   cells of the confusion matrix as a table with the variables
%   Stvarna (true class), Predviđena (predicted class) and Broj (count).
%   Pairs that never occur are left out, so T can have fewer than n rows.

    if nargin < 3
        n = 10;
    end

    classes = unique([string(yTrue(:)); string(yPred(:))]);
    if iscategorical(yTrue)
        classes = string(categories(yTrue));
    end
    cm = confusionmat(categorical(string(yTrue(:)), classes), ...
                      categorical(string(yPred(:)), classes), 'Order', categorical(classes));
    cm(logical(eye(size(cm)))) = 0;   % only the mistakes

    [counts, order] = sort(cm(:), 'descend');
    keep = min(n, nnz(counts));
    [row, col] = ind2sub(size(cm), order(1:keep));

    T = table(classes(row), classes(col), counts(1:keep), ...
        'VariableNames', {'Stvarna', 'Predviđena', 'Broj'});
end
