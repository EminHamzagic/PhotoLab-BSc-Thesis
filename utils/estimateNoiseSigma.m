function sigma = estimateNoiseSigma(img)
% ESTIMATENOISESIGMA  Robust (MAD) estimate of the Gaussian noise std, 0-255 scale.
%   Uses the diagonal difference kernel [1 -1; -1 1]/2, which has unit noise gain,
%   and the median-absolute-deviation constant 0.6745.

    g = im2double(img);
    if size(g, 3) > 1
        g = mean(g, 3) * sqrt(size(g, 3));   % averaging C channels divides std by sqrt(C)
    end
    g = g * 255;
    d = (g(1:end-1, 1:end-1) - g(1:end-1, 2:end) ...
       - g(2:end, 1:end-1) + g(2:end, 2:end)) / 2;
    sigma = median(abs(d(:))) / 0.6745;
end
