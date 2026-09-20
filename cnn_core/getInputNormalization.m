function layerNorm = getInputNormalization(normalization)
% getInputNormalization Map the DatasetManagerApp choice to imageInputLayer 'Normalization'
%   'MinMax' -> 'rescale-zero-one', 'Mean-Std' -> 'zscore', anything else -> 'none'.

    switch normalization
        case 'MinMax'
            layerNorm = 'rescale-zero-one';
        case 'Mean-Std'
            layerNorm = 'zscore';
        otherwise
            layerNorm = 'none';
    end
end
