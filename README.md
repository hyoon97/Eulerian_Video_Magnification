# Eulerian_Video_Magnification

## Initials and Color Transformation

```matlab
face_video = VideoReader('data/face.mp4');
baby_video = VideoReader('data/baby2.mp4');

original_video = zeros(face_video.NumFrames, face_video.Height, face_video.Width, 3);
idx = 1;
while hasFrame(face_video)
    frame = readFrame(face_video);
    original_video(idx, :, :, :) = rgb2ntsc(frame);
    idx = idx + 1;
end
```

## Laplacian Pyramid

```matlab
gaussian_video_pyramid = create_gaussian_pyramid(original_video, pyramid_levels);
```

```matlab
function gaussian_video_pyramid = create_gaussian_pyramid(original_video, pyramid_levels)

gaussian_video_pyramid = {};

[numFrames, H, W, channel] = size(original_video);

gaussian_video_pyramid{1} = original_video;

for level=1:pyramid_levels
    for frame=1:numFrames
        H_ = H/(2^level);
        W_ = W/(2^level);
        
%         tmp_frame = squeeze(original_video(frame, :, :, :));
%         for i=1:level
%             tmp_frame = impyramid(tmp_frame, 'reduce');
%         end

        gaussian_video_pyramid{level+1}(frame, :, :, :) = squeeze(impyramid(gaussian_video_pyramid{level}(frame, :, :, :), 'reduce'));
    end
end

end
```

## Temporal Filtering

```matlab
function filtered_video_pyramid = apply_temporal_filtering(laplacian_video_pyramid, numFrames, pyramid_levels)
%UNTITLED5 이 함수의 요약 설명 위치
%   자세한 설명 위치

Fs = 30;  % Sampling Frequency

N   = 256;   % Order
Fc1 = 0.83;  % First Cutoff Frequency
Fc2 = 1;     % Second Cutoff Frequency

result_pyramid = {};

for level=1:pyramid_levels
    [frame, row, col, channel] = size(laplacian_video_pyramid{level});
    
    fftHd = freqz(butterworthBandpassFilter(Fs, N, Fc1, Fc2), numFrames);
    fftHd_3D = reshape(fftHd, [1,1,numFrames]);
    
    fftHd_3D = repmat(fftHd_3D, [row, col, 1]);
    fftHd_3D = permute(fftHd_3D, [3,1,2]);
    
    fft_pixel_1 = fftn(laplacian_video_pyramid{level}(:, :, :, 1));
    filtered_1 = fft_pixel_1 .* fftHd_3D;
    result_pyramid{level}(:, :, :, 1) = abs(ifft(filtered_1));
    
    fft_pixel_2 = fftn(laplacian_video_pyramid{level}(:, :, :, 2));
    filtered_2 = fft_pixel_2 .* fftHd_3D;
    result_pyramid{level}(:, :, :, 2) = abs(ifft(filtered_2));
    
    fft_pixel_3 = fftn(laplacian_video_pyramid{level}(:, :, :, 3));
    filtered_3 = fft_pixel_3 .* fftHd_3D;
    result_pyramid{level}(:, :, :, 3) = abs(ifft(filtered_3));
    
end

filtered_video_pyramid = result_pyramid;

end

```

## Image Reconstruction
