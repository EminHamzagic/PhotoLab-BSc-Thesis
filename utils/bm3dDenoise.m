function out = bm3dDenoise(img, sigma255)
% BM3DDENOISE  Denoise a grayscale or RGB image with the external BM3D library.
%   out = bm3dDenoise(img, sigma255) - sigma255 is the noise standard deviation on
%   the 0-255 scale (the legacy BM3D/CBM3D convention, independent of image class).
%   Returns an image of the same class as img.
%
%   The library is the legacy Tampere release: [PSNR, y_est] = BM3D(y, z, sigma,
%   profile, print_to_screen), where y is a clean reference (1 = none), z the noisy
%   image; BM3D is grayscale-only, CBM3D handles RGB.

    if ~ensureBM3D()
        error('PhotoLab:missingBM3D', ...
            'BM3D biblioteka nije pronađena. Dodajte folder sa BM3D.m u MATLAB path.');
    end

    inClass = class(img);
    z = im2double(img);

    if size(z, 3) == 3
        [~, est] = CBM3D(1, z, sigma255, 'np', 0);
    elseif size(z, 3) == 1
        [~, est] = BM3D(1, z, sigma255, 'np', 0);
    else
        error('PhotoLab:badImage', 'BM3D podržava samo sive i RGB slike.');
    end

    est = min(max(est, 0), 1);
    switch inClass
        case 'uint8',  out = im2uint8(est);
        case 'uint16', out = im2uint16(est);
        otherwise,     out = cast(est, inClass);
    end
end
