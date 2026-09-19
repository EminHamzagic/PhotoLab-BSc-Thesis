function z = vaeSampleLatent(mu, logVar)
% vaeSampleLatent Reparameterization trick: z = mu + exp(0.5*logVar) .* epsilon
%   epsilon ~ N(0, I) is drawn outside the graph, so gradients flow through
%   mu and logVar only.

    epsilon = randn(size(mu), 'single');
    z = mu + exp(0.5 * logVar) .* epsilon;
end
