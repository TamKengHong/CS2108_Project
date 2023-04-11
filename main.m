% Shown below is how to use myJPEG to do JPEG-style compression on the
% image given, and to get back the image from our compressedData.  

img = im2uint8(imread("images/2.tif"));

% Specify quality: low, med, high.
quality = "low";

% Compression:
[compressedData, code_book] = myJPEG.compress(img, quality);

% Decompression:
% finalImg = myJPEG.decompress(compressedData, code_book, quality);

imshow(finalImg);


% % Data Analysis:
% img = im2uint8(imread("images/1.tif"));
% imwrite(img, "output.jpg");
% 
% clc; clear; close all;
% 
% % Load the 10 image files
% for i = 1:10
%     img{i} = im2uint8(imread(sprintf("images/%d.tif",i)));
%     img{i} = img{i}(:,:,1:3);
% end

% % Compress images using myJPEG
% tic
% for i = 1:10
%     compressedData_myJPEG{i} = myJPEG.compress(img{i});
%     size_myJPEG(i) = numel(compressedData_myJPEG{i});
% end
% time_myJPEG = toc;

% % Compress images using MATLAB's JPEG
% tic
% for i = 1:10
%     imwrite(img{i}, sprintf('%d.jpg', i));
%     compressedData_jpeg{i} = imread(sprintf('%d.jpg', i));
%     size_jpeg(i) = numel(compressedData_jpeg{i});
%     % delete(sprintf('%d.jpg', i));
% end
% time_jpeg = toc;
% 
% % Compress images using MATLAB's PNG
% tic
% for i = 1:10
%     imwrite(img{i}, sprintf('%d.png', i));
%     compressedData_png{i} = imread(sprintf('%d.png', i));
%     size_png(i) = numel(compressedData_png{i});
%     % delete(sprintf('%d.png', i));
% end
% time_png = toc;
% 
% % Plot the results
% figure;
% bar([size_jpeg; size_png]')
% legend('JPEG', 'PNG')
% xlabel('Image file')
% ylabel('Compressed data size (bytes)')
% title('Comparison of compression methods')
% 
% fprintf('JPEG compression time: %.2f seconds\n', time_jpeg);
% fprintf('PNG compression time: %.2f seconds\n', time_png);
