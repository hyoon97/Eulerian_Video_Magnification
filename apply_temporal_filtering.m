function filtered_pyramid = apply_temporal_filtering(laplacian_pyramid, numFrames, pyramid_levels)

Fs = 30;  % Sampling Frequency

N   = 256;   % Order
Fc1 = 0.83;  % First Cutoff Frequency
Fc2 = 1;     % Second Cutoff Frequency

fftHd = freqz(butterworthBandpassFilter(Fs, N, Fc1, Fc2), numFrames);

filtered_pyramid = {};

for level=1:pyramid_levels
    [H, W, c, frame] = size(laplacian_pyramid{level});
    
    filtered_pixel = zeros(H, W, c, frame);
    
    for h = 1:H
        for w = 1:W
            pixel = laplacian_pyramid{level}(h, w, 1, :);
            fft_pixel = fft(pixel);
            filtered_pixel(h, w, 1, :) = real(ifft(fft_pixel .* reshape(fftHd, [1,1,1,numFrames])));
            
            pixel = laplacian_pyramid{level}(h, w, 2, :);
            fft_pixel = fft(pixel);
            filtered_pixel(h, w, 2, :) = real(ifft(fft_pixel .* reshape(fftHd, [1,1,1,numFrames])));
            
            pixel = laplacian_pyramid{level}(h, w, 3, :);
            fft_pixel = fft(pixel);
            filtered_pixel(h, w, 3, :) = real(ifft(fft_pixel .* reshape(fftHd, [1,1,1,numFrames])));
        end
    end
    
    filtered_pyramid{level} = filtered_pixel;
    
end
