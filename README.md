# Eulerian_Video_Magnification

## Initials and Color Transformation

At this stage, the videos are imported, and each frame are converted from RGB format to YIQ format using the following code
   
```matlab
% video = VideoReader('data/face.mp4');
video = VideoReader('data/baby2.mp4');

original_video = zeros(video.Height,video.Width, 3, video.NumFrames);
idx = 1;
while hasFrame(video)
    frame = readFrame(video);
    original_video(:, :, :, idx) = rgb2ntsc(im2double(frame)/255);
    idx = idx + 1;
end
```

## Laplacian Pyramid

After converting the video format from RGB to YIQ, gaussian pyramid is constructed via calling the function `create_laplacian_pyramid`.  
The gaussian pyramid is constructed via using `impyramid(image, 'direction')` to compute gaussian pyramid in the direction of `reduce`.   
Gaussian pyramid is stored in the shape of `[frame, height, width, channel]` to ease the conversion from time domain to frequency for temporal filtering at the next stage.   
Using the constructed gaussian pyramid, laplacian pyramid is constructed by subtracting each gaussian layer by its next layer.   

```matlab
pyramid_levels = 4;

[gaussian_pyramid, laplacian_pyramid] = create_laplacian_pyramid(original_video,pyramid_levels);
```

```matlab
function [gaussian_pyramid, laplacian_pyramid] = create_laplacian_pyramid(original_video,pyramid_levels)

gaussian_pyramid = {};
gaussian_pyramid{1} = original_video;

laplacian_video_pyramid = {};

for level=1:pyramid_levels-1
    [H, W, ~, ~] = size(gaussian_pyramid{level});
    gaussian_pyramid{level+1} = impyramid(gaussian_pyramid{level}, 'reduce');
    resized = imresize(gaussian_pyramid{level+1}, [H, W]);
    laplacian_pyramid{level} = gaussian_pyramid{level} - resized;
end

laplacian_pyramid{end+1} = gaussian_pyramid{end};
end
```

The following images shows the result of gaussian and laplacian pyramid.   

### Guassian Pyramid 

![Alt text](/images/gaussian_1.png)
![Alt text](/images/gaussian_2.png)
![Alt text](/images/gaussian_3.png)
![Alt text](/images/gaussian_4.png)

### Laplacian Pyramid

![Alt text](/images/laplacian_1.png)
![Alt text](/images/laplacian_2.png)
![Alt text](/images/laplacian_3.png)
![Alt text](/images/laplacian_4.png)

## Temporal Filtering    
The constructed laplacian pyramid is then filtered using the butterworth bandpass filter.   
The butterworth bandpass filter is created using the provided code in `./src` folder.   
Before applying the filter to pixels, the pixels are converted from time domain to frequency domain so that the filter can be multiplied to pixels.  
The filtered pixels are converted back to time domain and used to construct filtered pyramid.  

```matlab
filtered_pyramid = apply_temporal_filtering(laplacian_pyramid, video.NumFrames, pyramid_levels);
```
```matlab
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
```

## Extracting Frequency Band
```matlab
frequency_band = [];
for frame = 1:video.NumFrames
    magnitude = 0;
    for level = 1:pyramid_levels
        laplacian_pyramid_frequency = fft(laplacian_pyramid{level}(:,:,:,frame));
        magnitude = magnitude + mean(abs(laplacian_pyramid_frequency(:)));
    end
    frequency_band = [frequency_band; magnitude];
end
plot(frequency_band);
xlim([0,300]);
```

## Image Reconstruction
Each frame from video are reconstructed by adding laplacian pyramid and filtered pyramid to the original image.
```matlab 
reconstructed_video = reconstruct_video(laplacian_pyramid,filtered_pyramid, pyramid_levels);
```

The last layer of laplacian pyramid is downsized original image. The filtered image, which multiplied by the amplifying factor, is added to the last layer of the laplacian pyramid.  
Then the image is upsampled and are added to the next layer of laplacian pyramid. This is repeated until original image is recovered. 

```matlab
function reconstructed_video = reconstruct_video(laplacian_pyramid,filtered_pyramid, pyramid_levels)

original = laplacian_pyramid{end} + filtered_pyramid{end} * 120;

for level=1:pyramid_levels-1
    [H, W, c, frame] = size(laplacian_pyramid{pyramid_levels - level});
    resized = imresize(original, [H, W]);
    
    original = laplacian_pyramid{pyramid_levels - level} + resized;
end

reconstructed_video = original;
end
```

Finally, the magnified video is saved as `.mp4` file using the following code
```matlab
v = VideoWriter('test.mp4', 'MPEG-4');
open(v);
for i=1:video.NumFrames
    frame(:,:,:) = reconstructed_video(:,:,:,i)*255;
    frame = ntsc2rgb(frame);
    writeVideo(v, frame);
end
close(v);
```

The following videos are result of magnifying `face.mp4` and `baby2.mp4`

![Alt text](https://youtu.be/_dFyt0PCUrg)
![Alt text](https://youtu.be/wjo-sh04AtM)

