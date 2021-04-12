function reconstructed_video = reconstruct_video(laplacian_pyramid,filtered_pyramid, pyramid_levels)

original = laplacian_pyramid{end} + filtered_pyramid{end} * 120;

for level=1:pyramid_levels-1
    [H, W, c, frame] = size(laplacian_pyramid{pyramid_levels - level});
    resized = imresize(original, [H, W]);
    
    original = laplacian_pyramid{pyramid_levels - level} + resized;
end

reconstructed_video = original;
end

