% Shown below is how to use myJPEG to do JPEG-style compression on the
% image given, and to get back the image from our compressedData.  
img = im2uint8(imread("images/4.tif"));

% Specify quality: low, med, high.
quality = "high";

% Compression:
[compressedData, code_book] = myJPEG.compress(img, quality);

% Decompression:
finalImg = myJPEG.decompress(compressedData, code_book, quality);

imshow(finalImg);