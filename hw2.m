clear all; clc; 

addpath('./src');

video = VideoReader('data/face.mp4');
% video = VideoReader('data/baby2.mp4');

original_video = zeros(video.Height,video.Width, 3, video.NumFrames);
idx = 1;
while hasFrame(video)
    frame = readFrame(video);
    original_video(:, :, :, idx) = rgb2ntsc(im2double(frame)/255);
    idx = idx + 1;
end

pyramid_levels = 4;

[gaussian_pyramid, laplacian_pyramid] = create_laplacian_pyramid(original_video,pyramid_levels);

filtered_pyramid = apply_temporal_filtering(laplacian_pyramid, video.NumFrames, pyramid_levels);

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

reconstructed_video = reconstruct_video(laplacian_pyramid,filtered_pyramid, pyramid_levels);

v = VideoWriter('test.mp4', 'MPEG-4');
open(v);
for i=1:video.NumFrames
    frame(:,:,:) = reconstructed_video(:,:,:,i)*255;
    frame = ntsc2rgb(frame);
    writeVideo(v, frame);
end
close(v);
