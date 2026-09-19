function out = blockMatchingDenoise(img, sigma255, opts)
% BLOCKMATCHINGDENOISE  Blind block-matching + collaborative filtering denoiser.
%   out = blockMatchingDenoise(img, sigma255, opts)
%
%   A compact version of the first BM3D step that works only on the noisy image:
%     1. For every reference block, find the K most similar blocks (SSD) in a
%        +-SearchRange window (computed for all blocks at once, per offset).
%     2. Stack them, apply a 3-D transform (2-D DCT per block + DCT across the
%        stack) and hard-threshold the coefficients at Lambda*sigma.
%     3. Invert and aggregate the filtered blocks with weights 1/nnz.
%   RGB images are handled in an orthonormal opponent colour space: matching is
%   done on the luminance channel and the same groups filter all three channels.
%
%   sigma255 - noise std on the 0-255 scale.
%   opts (all optional): BlockSize (8), Step (3), SearchRange (11), NumBlocks (16),
%   Lambda (2.7), ProgressFcn (function handle called with a fraction in 0..1).

    if nargin < 3, opts = struct(); end
    B      = getOpt(opts, 'BlockSize', 8);
    step   = getOpt(opts, 'Step', 3);
    S      = getOpt(opts, 'SearchRange', 11);
    K      = getOpt(opts, 'NumBlocks', 16);
    lambda = getOpt(opts, 'Lambda', 2.7);
    prog   = getOpt(opts, 'ProgressFcn', []);

    inClass = class(img);
    z = im2double(img);
    [H, W, C] = size(z);
    assert(C == 1 || C == 3, 'Podržane su samo sive i RGB slike.');
    assert(H >= B && W >= B, 'Slika je premala za odabranu veličinu bloka.');
    s = sigma255 / 255;

    % Opponent colour transform (orthonormal, so sigma is unchanged per channel)
    T = [1/sqrt(3) 1/sqrt(3) 1/sqrt(3); 1/sqrt(2) 0 -1/sqrt(2); 1/sqrt(6) -2/sqrt(6) 1/sqrt(6)];
    Zc = reshape(z, H * W, C);
    if C == 3, Zc = Zc * T'; end
    y = reshape(Zc(:, 1), H, W);          % matching is done on this channel

    % Reference block positions (last row/column always included)
    ri = unique([1:step:H - B + 1, H - B + 1]);
    ci = unique([1:step:W - B + 1, W - B + 1]);
    nR = numel(ri); nC = numel(ci);

    % Distance cube: D(r,c,o) = mean SSD between the block at (ri(r),ci(c)) and
    % the block displaced by offset o (inf where the partner leaves the image)
    [DX, DY] = meshgrid(-S:S, -S:S);
    offs = [DY(:) DX(:)];
    nO = size(offs, 1);
    D = inf(nR, nC, nO, 'single');
    ones1 = ones(B, 1) / B;
    for o = 1:nO
        dy = offs(o, 1); dx = offs(o, 2);
        okR = ri + dy >= 1 & ri + dy <= H - B + 1;
        okC = ci + dx >= 1 & ci + dx <= W - B + 1;
        if ~any(okR) || ~any(okC), continue; end
        d2 = (y - circshift(y, [-dy -dx])) .^ 2;
        M = conv2(ones1, ones1', d2, 'valid');
        sub = M(ri, ci);
        sub(~okR, :) = inf;
        sub(:, ~okC) = inf;
        D(:, :, o) = single(sub);
        if ~isempty(prog) && mod(o, 20) == 0, prog(0.3 * o / nO); end
    end

    Dm = dctmtx(B);
    base = (0:B - 1)' + (0:B - 1) * H;     % linear-index offsets of one block
    num = zeros(H * W, C);
    den = zeros(H * W, 1);

    for r = 1:nR
        for c = 1:nC
            d = squeeze(D(r, c, :));
            [dv, idx] = mink(d, K);
            idx = idx(isfinite(dv));
            kk = numel(idx);

            starts = (ri(r) + offs(idx, 1)) + (ci(c) + offs(idx, 2) - 1) * H;
            lin = reshape(starts, 1, 1, kk) + base;             % B x B x kk
            G = reshape(Zc(lin(:), :), B, B, kk, C);

            % 2-D DCT per block, then DCT across the stack, per channel
            G = pagemtimes(pagemtimes(Dm, G), Dm');
            X = reshape(permute(G, [1 2 4 3]), B * B * C, kk);
            Tk = dctmtx(kk);
            X = X * Tk';
            keep = abs(X) > lambda * s;
            X(~keep) = 0;
            wgt = 1 / max(1, nnz(keep));
            X = X * Tk;
            G = ipermute(reshape(X, B, B, C, kk), [1 2 4 3]);
            G = pagemtimes(pagemtimes(Dm', G), Dm);

            for q = 1:kk
                p = lin(:, :, q);
                num(p, :) = num(p, :) + wgt * reshape(G(:, :, q, :), B * B, C);
                den(p) = den(p) + wgt;
            end
        end
        if ~isempty(prog), prog(0.3 + 0.7 * r / nR); end
    end

    est = Zc;
    has = den > 0;
    est(has, :) = num(has, :) ./ den(has);
    if C == 3, est = est * T; end          % T is orthonormal: inverse is T'
    est = min(max(reshape(est, H, W, C), 0), 1);

    switch inClass
        case 'uint8',  out = im2uint8(est);
        case 'uint16', out = im2uint16(est);
        otherwise,     out = cast(est, inClass);
    end
end

function v = getOpt(opts, name, default)
    if isfield(opts, name) && ~isempty(opts.(name))
        v = opts.(name);
    else
        v = default;
    end
end
