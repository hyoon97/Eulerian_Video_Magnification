# Eulerian_Video_Magnification

## Initials and Color Transformation

At this stage, the videos are imported, and each frame are converted from RGB format to YIQ format using the following code
   
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

After converting the video format from RGB to YIQ, gaussian pyramid is constructed via calling the function `create_gaussian_pyramid`.
The gaussian pyramid is constructed via using `impyramid(image, 'direction')` to compute gaussian pyramid in the direction of #reduce# or #expand#. 
Gaussian pyramid is stored in the shape of `[frame, height, width, channel]` to ease the conversion from time domain to frequency for temporal filtering at the next stage.
```matlab
gaussian_video_pyramid = create_gaussian_pyramid(original_video, pyramid_levels);
```
```matlab
function gaussian_video_pyramid = create_gaussian_pyramid(original_video, pyramid_levels)

gaussian_video_pyramid = {};

gaussian_video_pyramid{1} = original_video;

for level=1:pyramid_levels
    gaussian_video_pyramid{level+1} = impyramid(gaussian_video_pyramid{level}, 'reduce');
end

end
```

With the gaussian pyramid, laplacian pyramid is constructed via subtracting each layer of gaussian pyramid by its next layer. 

```matlab
laplacian_video_pyramid = create_laplacian_pyramid(gaussian_video_pyramid,pyramid_levels);
```
```
function laplacian_video_pyramid = create_laplacian_pyramid(gaussian_video_pyramid,pyramid_levels)

laplacian_video_pyramid = {};

for level=1:pyramid_levels
    [H, W, ~, numFrames] = size(gaussian_video_pyramid{level});
    for frame=1:numFrames
        laplacian_video_pyramid{level}(:, :, :, frame) = gaussian_video_pyramid{level}(:, :, :, frame) - imresize(impyramid(gaussian_video_pyramid{level+1}(:,:,:, frame),'expand'), [H, W]);
    end
end

laplacian_video_pyramid{end+1} = gaussian_video_pyramid{end};
end
```

## Temporal Filtering

```matlab
function filtered_video_pyramid = apply_temporal_filtering(laplacian_video_pyramid, numFrames, pyramid_levels)

Fs = 30;  % Sampling Frequency

N   = 256;   % Order
Fc1 = 0.83;  % First Cutoff Frequency
Fc2 = 1;     % Second Cutoff Frequency

fftHd = freqz(butterworthBandpassFilter(Fs, N, Fc1, Fc2), numFrames);

result_pyramid = {};

for level=1:pyramid_levels
    [row, col, channel, frame] = size(laplacian_video_pyramid{level});
    
    filtered_pixel = zeros(row, col, channel, frame);
    
    for r = 1:row
        for c = 1:col
            pixel = laplacian_video_pyramid{level}(r, c, 1, :);
            fft_pixel = fft(pixel);
            filtered_pixel(r, c, 1, :) = abs(ifft(fft_pixel .* reshape(fftHd, [1,1,1,numFrames])));
            
            pixel = laplacian_video_pyramid{level}(r, c, 2, :);
            fft_pixel = fft(pixel);
            filtered_pixel(r, c, 2, :) = abs(ifft(fft_pixel .* reshape(fftHd, [1,1,1,numFrames])));
            
            pixel = laplacian_video_pyramid{level}(r, c, 3, :);
            fft_pixel = fft(pixel);
            filtered_pixel(r, c, 3, :) = abs(ifft(fft_pixel .* reshape(fftHd, [1,1,1,numFrames])));
        end
    end
    
    result_pyramid{level} = filtered_pixel;
    
end

filtered_video_pyramid = result_pyramid;

```

## Image Reconstruction
Each frame from video are reconstructed by adding amplifying factors to the orginial frame.
```matlab 
amplified_video = collapse_laplacian_pyramid(filtered_video_pyramid, pyramid_levels, face_video.NumFrames);

result = original_video(:, :, :, :) + amplified_video(:, :, :, :);
```

The amplifying factor is obtained expanding filtered laplacian pyramid to the original size. After expanding all layers from filtered laplacian pyramid, the sum of expanded laplacian layers become the amplifying factor used to magnify the motion inside the video.

```matlab
amplified_filter = filtered_video_pyramid{1};

for frame=1:numFrames
    
    for level=2:pyramid_levels
        [H, W, channel, ~] = size(filtered_video_pyramid{1});
        tmp_frame = filtered_video_pyramid{level}(:, :, :, frame);
        
        for i=2:level
            tmp_frame = impyramid(tmp_frame,'expand');
        end
        tmp_frame = imresize(tmp_frame, [H, W]);
        
%         if level == 4 || level == 5
%             amplified_filter = amplified_filter + tmp_frame;
%         else
%             amplified_filter = amplified_filter + tmp_frame;
%         end
        amplified_filter = amplified_filter + tmp_frame;
    end
    
end

result_pyramid = amplified_filter;

```

Finally, the magnified video is saved as `.mp4` file using the following code
```matlab
v = VideoWriter('test.mp4','MPEG-4');
open(v);
for i=1:face_video.NumFrames
    frame(:, :, :) = result(:,:,:, i);
    frame = ntsc2rgb(frame);
    writeVideo(v,frame);
end
```
