% Data Analysis:
% Part 0: Define variables, load the image files & make sure they correct format.
n = 21; % number of images.
qualities = ["low", "med", "high"];
img = zeros(n);
original_size = zeros(n);

size_myJPEG = zeros(n, 3);  % 1 is low, 2 is med, 3 is high.
size_jpeg = zeros(n);
size_png = zeros(n);
time_myJPEG_compress = zeros(n, 3);
time_jpeg = zeros(n);
time_png = zeros(n);

decompressed_imgs = zeros(n, 3); % decompressed rgb images after myJPEG.decompress()
time_myJPEG_decompress = zeros(n, 3);

for i = 1:n
    file_path = sprintf("images/%d.tif",i);
    img{i} = im2uint8(imread(file_path)); % 10/16 bit channel -> 8 bit channel.
    img{i} = img{i}(:,:,1:3); % RGBA -> RGB
    original_size = dir(filepath).bytes;
end


% Part 1: Get all the data. 
% Get the compressed size, the runtime, and result image for each compression.

% Compress images using myJPEG & record their timing.
for i = 1:n
    for j = 1:3
    tic; % time each compression.
    [compressedData, code_book] = myJPEG.compress(img(i), qualities(j));
    time_myJPEG_compress(i, j) = toc;
    size_myJPEG(i, j) = numel(compressedData) / 8; % bin to bytes

    tic; % time each decompression.
    decompressed_imgs(i, j) = myJPEG.decompress(compressedData, code_book, qualities(j));
    time_myJPEG_decompress(i, j) = toc;
    end
end

% Compress images using MATLAB's JPEG & record their timing.
for i = 1:n
    tic
    imwrite(img(i), sprintf('%d.jpg', i));
    size_jpeg(i) = dir(sprintf('%d.jpg', i)).bytes; % directly get bytes.
    time_jpeg(i) = toc;
end

% Compress images using MATLAB's PNG & record their timing.
for i = 1:n
    tic
    imwrite(img(i), sprintf('%d.png', i));
    size_png(i) = dir(sprintf('%d.png', i)).bytes;
    time_png(i) = toc;
end

% Part 2: Plot the results

% 2.1: myJPEG: low, med, high quality comparison.
% 2.1.1: myJPEG image plot of 2.tiff for low, med, high quality.
figure
subplot(1,4,1);
imshow(img{2}); title("Original Image");
for i = 1:3
    subplot(1,4,i+1);
    imshow(decompressed_imgs(2,:,i)); 
    title(sprintf("Decompressed: %s Quality", qualities(i)));
end
sgtitle("Compression Results for Image 2");

% 2.1.2: myJPEG compression size comparison (total, avg, compression ratio)
total_size_myJPEG = sum(size_myJPEG,2);
compression_ratio_myJPEG = original_size ./ total_size_myJPEG;
figure
subplot(1,3,1);
bar(original_size); title("Total Original Size");
subplot(1,3,2);
bar(total_size_myJPEG); title("Total Compressed Size");
subplot(1,3,3);
bar(compression_ratio_myJPEG); title("Compression Ratio");
sgtitle("Compression Results for myJPEG");

% 2.1.3 myJPEG runtime comparison for compression & decompression
total_time_myJPEG_compress = sum(time_myJPEG_compress,2);
avg_time_myJPEG_compress = mean(time_myJPEG_compress,2);
total_time_myJPEG_decompress = sum(time_myJPEG_decompress,2);
avg_time_myJPEG_decompress = mean(time_myJPEG_decompress,2);
figure
subplot(2,2,1);
bar(total_time_myJPEG_compress); title("Total Compression Time");
subplot(2,2,2);
bar(avg_time_myJPEG_compress); title("Average Compression Time");
subplot(2,2,3);
bar(total_time_myJPEG_decompress); title("Total Decompression Time");
subplot(2,2,4);
bar(avg_time_myJPEG_decompress); title("Average Decompression Time");
sgtitle("Runtime Comparison for myJPEG");

% 2.2: Comparison of compression runtime between myJPEG "med", MATLAB JPEG
% and MATLAB PNG across categories.
figure
subplot(1,3,1);
bar(time_myJPEG_compress(:,2)); title("myJPEG: Medium Quality Compression");
subplot(1,3,2);
bar(time_jpeg); title("MATLAB JPEG Compression");
subplot(1,3,3);
bar(time_png); title("MATLAB PNG Compression");
sgtitle("Compression Runtime Comparison");

% 2.3: Comparison of compression size between myJPEG "med", MATLAB JPEG and
% MATLAB PNG across categories.
figure
subplot(1,3,1);
bar(size_myJPEG(:,2)); title("myJPEG: Medium Quality Compression Size");
subplot(1,3,2);
bar(size_jpeg); title("MATLAB JPEG Compression Size");
subplot(1,3,3);
bar(size_png); title("MATLAB PNG Compression Size");
sgtitle("Compression Size Comparison");
