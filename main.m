img = imread("images/7.tif");
if max(img) > 255 
    % 16 bit image, can just divide by 256 to get 8 bit image.
    img = img / 256;
end

% Specify quality: low, med, high.

% Compression:
compressedData = myJPEG.compress(img, "low");

% Decompression:
finalImg = myJPEG.decompress(compressedData);

imshow(finalImg)
