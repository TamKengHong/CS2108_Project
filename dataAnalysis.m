% Downsize all our images into at most 1000 x 1000
for i = 1:21
    img = imread(sprintf("sourceImages/%d.tif",i));
    [height, width, ~] = size(img);
    
    % calculate new dimensions while keeping aspect ratio
    if height > width
        new_height = 1000;
        new_width = round(new_height/height*width);
    else
        new_width = 1000;
        new_height = round(new_width/width*height);
    end
    % resize image, set make sure its uint8, get rgb channels only.
    img = im2uint8(imresize(img, [new_height, new_width]));
    img = img(:,:,1:3);
    imwrite(img, sprintf("out/%d.tif",i));
end


% Data Analysis:
% Part 0: Define variables, load the image files & make sure they correct format.
n = 21; % number of images.
qualities = ["low", "med", "high"];
imgs = cell(n, 1);
original_size = zeros(n, 1);

size_myJPEG = zeros(n, 3);  % 1 is low, 2 is med, 3 is high.
size_jpeg = zeros(n, 1);
size_png = zeros(n, 1);
time_myJPEG_compress = zeros(n, 3);
time_jpeg = zeros(n, 1);
time_png = zeros(n, 1);

decompressed_imgs = cell(n, 3); % decompressed rgb images after myJPEG.decompress()
time_myJPEG_decompress = zeros(n, 3);

for i = 1:n
    file_path = sprintf("images/%d.tif",i);
    imgs{i} = imread(file_path);
    original_size(i) = dir(file_path).bytes;
end


% Part 1: Get all the data. 
% Get the compressed size, the runtime, and result image for each compression.

% Compress images using MATLAB's JPEG & record their timing.
for i = 1:n
    tic
    imwrite(imgs{i}, sprintf('%d.jpg', i));
    size_jpeg(i) = dir(sprintf('%d.jpg', i)).bytes; % directly get bytes.
    time_jpeg(i) = toc;
end

% Compress images using MATLAB's PNG & record their timing.
for i = 1:n
    tic
    imwrite(imgs{i}, sprintf('%d.png', i));
    size_png(i) = dir(sprintf('%d.png', i)).bytes;
    time_png(i) = toc;
end

% Compress images using myJPEG & record their timing.
for i = 1:n
    for j = 1:3
    tic; % time each compression.
    [compressedData, code_book] = myJPEG.compress(imgs{i}, qualities(j));
    time_myJPEG_compress(i, j) = toc;
    size_myJPEG(i, j) = (numel(compressedData) + numel(code_book)) / 8; % bin to bytes

    tic; % time each decompression.
    decompressed_imgs{i, j} = myJPEG.decompress(compressedData, code_book, qualities(j));
    time_myJPEG_decompress(i, j) = toc;
    disp([i j])
    disp(time_myJPEG_compress(i, j));
    disp(time_myJPEG_decompress(i, j));
    end
end

% Part 2: Plot the results

% 2.1: myJPEG: low, med, high quality comparison.
% 2.1.1: myJPEG image plot of 2.tiff for low, med, high quality.
figure
subplot(2,2,1);
imshow(imgs{2}); title("Original Image");
subplot(2,2,2);
imshow(decompressed_imgs{2,1}); title("Decompressed: Low Quality");
subplot(2,2,3);
imshow(decompressed_imgs{2,1}); title("Decompressed: Med Quality");
subplot(2,2,4);
imshow(decompressed_imgs{2,1}); title("Decompressed: High Quality");
sgtitle("Compression Results for Image 2");

% 2.1.2: myJPEG compression size comparison (total, compression ratio)
total_size_myJPEG = sum(size_myJPEG,1);
total_original_size = sum(original_size);
resultantImgSize_myJPEG = 100 * total_size_myJPEG ./ total_original_size;
figure
subplot(1,3,1);
bar(total_original_size); title("Total Original Size"); set(gca,'xticklabel',qualities);
subplot(1,3,2);
bar(total_size_myJPEG); title("Total Compressed Size"); set(gca,'xticklabel',qualities);
subplot(1,3,3);
bar(resultantImgSize_myJPEG); title("Compressed / Original Size (%)"); set(gca,'xticklabel',qualities);
sgtitle("Compression Size (in bytes) for myJPEG");

% 2.1.3 myJPEG runtime comparison for compression & decompression
total_time_myJPEG_compress = sum(time_myJPEG_compress,1);
avg_time_myJPEG_compress = mean(time_myJPEG_compress,1);
total_time_myJPEG_decompress = sum(time_myJPEG_decompress,1);
avg_time_myJPEG_decompress = mean(time_myJPEG_decompress,1);
total_time = sum(time_myJPEG_compress, "all") + sum(time_myJPEG_decompress, "all");
figure
subplot(2,2,1);
bar(total_time_myJPEG_compress); title("Total Compression Time"); set(gca,'xticklabel',qualities);
subplot(2,2,2);
bar(avg_time_myJPEG_compress); title("Average Compression Time"); set(gca,'xticklabel',qualities);
subplot(2,2,3);
bar(total_time_myJPEG_decompress); title("Total Decompression Time"); set(gca,'xticklabel',qualities);
subplot(2,2,4);
bar(avg_time_myJPEG_decompress); title("Average Decompression Time"); set(gca,'xticklabel',qualities);
sgtitle(sprintf("Runtime Comparison (in seconds) for myJPEG. (Total Time Taken = %d seconds)", int16(total_time)));

% 2.2: Comparison of average compression runtime between myJPEG "high", MATLAB JPEG
% and MATLAB PNG across categories + total.
categories = ["Buildings", "Nature", "Vehicles", "Animals", "People", "Art Paintings", "Space"];
xs = ["myJPEG", "JPEG", "PNG"];
cat_time_myJPEG_compress = reshape(time_myJPEG_compress(:,3), [7, 3]);
cat_time_jpeg = reshape(time_jpeg, [7, 3]);
cat_time_png = reshape(time_png, [7, 3]);

figure
for i = 1:7 % each category
    subplot(2,4,i);
    bar([mean(cat_time_myJPEG_compress(i)), mean(cat_time_jpeg(i)), mean(cat_time_png(i))]);
    set(gca,'xticklabel',xs);
    title(categories(i));
end

subplot(2,4,8);
bar([mean(time_myJPEG_compress(:,3), "all"), mean(time_jpeg, "all"), mean(time_png,"all")]);
set(gca,'xticklabel',xs); title("All Categories");
sgtitle("Average Compression Runtime Comparison (in seconds) between myJPEG 'high', MATLAB JPEG, MATLAB PNG");

% 2.3: Comparison of average compression size between myJPEG "med", MATLAB JPEG and
% MATLAB PNG across categories.
cat_size_myJPEG = reshape(size_myJPEG(:,3), [7, 3]);
cat_size_jpeg = reshape(size_jpeg, [7, 3]);
cat_size_png = reshape(size_png, [7, 3]);

figure
for i = 1:7 % each category
    subplot(2,4,i);
    bar([mean(cat_size_myJPEG(i)), mean(cat_size_jpeg(i)), mean(cat_size_png(i))]);
    set(gca,'xticklabel',xs);
    title(categories(i));
end

subplot(2,4,8);
bar([mean(size_myJPEG(:,3), "all"), mean(size_jpeg, "all"), mean(size_png,"all")]);
set(gca,'xticklabel',xs); title("All Categories");
sgtitle("Average Compression Size Comparison (in bytes) between myJPEG 'high', MATLAB JPEG, MATLAB PNG");
