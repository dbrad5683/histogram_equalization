fclose all;
close all;
clear;
clc;

fid = fopen('result.bin', 'rb');
rows = fread(fid, 1, 'int'); 
cols = fread(fid, 1, 'int');
data_in = fread(fid, [rows, cols], 'uchar')';
data_out = fread(fid, [rows, cols], 'uchar')';
fclose(fid);

figure();
colormap(gcf, 'gray');
subplot(2, 1, 1);
imagesc(data_in, [0, 255]);
title('Before');
subplot(2, 1, 2);
imagesc(data_out, [0, 255]);
title('After');

fprintf('Before: min = %u, max = %u\n', min(data_in(:)), max(data_in(:)));
fprintf('After: min = %u, max = %u\n', min(data_out(:)), max(data_out(:)));