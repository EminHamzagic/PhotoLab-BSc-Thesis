function makeFilterDemoImages(outDir)
% MAKEFILTERDEMOIMAGES  Regenerates the two clean 256x256 RGB demo images used to try
%   the denoising filters (Filters.mlapp). Developer tool, not called at run time.
%   The images are CLEAN - the app adds the noise itself. PNG on purpose: JPEG
%   artefacts would be indistinguishable from residual noise.
%
%   makeFilterDemoImages()          writes into +SampleImages/ next to tools/
%   makeFilterDemoImages(outDir)    writes into outDir

    if nargin < 1
        outDir = fullfile(fileparts(fileparts(mfilename('fullpath'))), '+SampleImages');
    end
    imwrite(brickPattern(256),  fullfile(outDir, 'demo_bricks_256.png'));
    imwrite(gradientScene(256), fullfile(outDir, 'demo_gradient_256.png'));
end

function I = brickPattern(N)
% Best case for block matching: every brick is a pixel-exact copy of one of four
% prototypes, so blocks have many exact twins inside the search window.
    bw = 32; bh = 16; mortar = 2;
    rng(7, 'twister');
    base = [0.62 0.29 0.22; 0.70 0.35 0.26; 0.55 0.24 0.19; 0.66 0.32 0.20];
    proto = zeros(bh, bw, 3, 4);
    for k = 1:4
        proto(:, :, :, k) = reshape(base(k, :), 1, 1, 3) + 0.06 * (rand(bh, bw) - 0.5);
    end
    I = 0.82 * ones(N + 2 * bh, N + 2 * bw, 3);
    for row = 0:ceil((N + 2 * bh) / bh) - 1
        y0 = row * bh + 1;
        if y0 + bh - 1 > size(I, 1), break; end
        shift = mod(row, 2) * bw / 2;
        for c = 0:ceil((N + 2 * bw) / bw) - 1
            x0 = c * bw + shift + 1;
            if x0 + bw - 1 > size(I, 2), break; end
            k = 1 + mod(row * 7 + c * 3, 4);
            I(y0:y0 + bh - mortar - 1, x0:x0 + bw - mortar - 1, :) = ...
                proto(1:bh - mortar, 1:bw - mortar, :, k);
        end
    end
    I = im2uint8(min(max(I(bh + 1:bh + N, bw + 1:bw + N, :), 0), 1));
end

function I = gradientScene(N)
% Classic BM3D showcase: smooth/flat areas plus hard edges and thin high-contrast bars.
    [X, Y] = meshgrid(linspace(0, 1, N), linspace(0, 1, N));
    I = cat(3, 0.35 + 0.45 * (1 - Y), 0.55 + 0.35 * (1 - Y), 0.85 - 0.15 * Y);
    I = setRegion(I, Y > 0.68, [0.30 0.42 0.22]);
    I = setRegion(I, (X - 0.30).^2 + (Y - 0.35).^2 < 0.010, [0.95 0.90 0.30]);
    I = setRegion(I, X > 0.56 & X < 0.90 & Y > 0.38 & Y < 0.45, [0.45 0.20 0.16]);
    I = setRegion(I, X > 0.60 & X < 0.86 & Y > 0.45 & Y < 0.72, [0.80 0.78 0.72]);
    I = setRegion(I, X > 0.10 & X < 0.12 & Y > 0.75 & Y < 0.95, [0.05 0.05 0.05]);
    I = setRegion(I, X > 0.15 & X < 0.17 & Y > 0.75 & Y < 0.95, [0.98 0.98 0.98]);
    I = im2uint8(min(max(I, 0), 1));
end

function I = setRegion(I, mask, rgb)
    for c = 1:3
        ch = I(:, :, c);
        ch(mask) = rgb(c);
        I(:, :, c) = ch;
    end
end
