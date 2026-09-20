function n = countLearnables(net)
% countLearnables Number of learnable parameters of a SeriesNetwork / DAGNetwork
%   Sums Weights, Bias, Scale and Offset of every layer that has them
%   (convolution, fully connected, batch normalization).

    n = 0;
    props = {'Weights', 'Bias', 'Scale', 'Offset'};
    for k = 1:numel(net.Layers)
        layer = net.Layers(k);
        for j = 1:numel(props)
            if isprop(layer, props{j})
                n = n + numel(layer.(props{j}));
            end
        end
    end
end
