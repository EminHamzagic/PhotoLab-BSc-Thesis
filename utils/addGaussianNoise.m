function noisy = addGaussianNoise(img, sigma255)
% ADDGAUSSIANNOISE  Adds zero-mean white Gaussian noise of std sigma255 (0-255 scale).
%   Returns an image of the same class as img (values clamped to the valid range).

    inClass = class(img);
    z = im2double(img) + (sigma255 / 255) * randn(size(img));
    z = min(max(z, 0), 1);
    switch inClass
        case 'uint8',  noisy = im2uint8(z);
        case 'uint16', noisy = im2uint16(z);
        otherwise,     noisy = cast(z, inClass);
    end
end
