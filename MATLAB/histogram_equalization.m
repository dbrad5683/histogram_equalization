function [h, s, idx] = histogram_equalization(filename)

    rgb = imread(filename);
    ycbcr = rgb2ycbcr(rgb);
    y = ycbcr(:, :, 1);
    
    h = histcounts(y, 256);
    s = cumsum(h);
    [~, idx] = min(s(s > 0));
    
end