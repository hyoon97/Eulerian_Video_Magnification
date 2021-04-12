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