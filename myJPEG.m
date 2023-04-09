classdef myJPEG
    methods (Static)
        % RGB to YCbCr conversion, based on ITU-R BT.601 standard
        % https://en.wikipedia.org/wiki/YCbCr#ITU-R_BT.601_conversion
        function ycbcrImg = rgb2ycbcr(rgbImg)
            rgbImg = double(rgbImg);
            r = rgbImg(:,:,1);
            g = rgbImg(:,:,2);
            b = rgbImg(:,:,3);

            % Convert to ycbcr
            y = 16 + (65.481/255) * r + (128.553/255) * g + (24.966/255) * b;
            cb = 128 - (37.797/255) * r - (74.203/255) * g + (112/255) * b;
            cr = 128 + (112/255) * r - (93.786/255) * g - (18.214/255) * b;
            
            ycbcrImg = cat(3, y, cb, cr);
        end
        
        % YCbCr to RGB conversion, also based on ITU-R BT.601 standard.
        function rgbImg = ycbcr2rgb(ycbcrImg)
            y = ycbcrImg(:,:,1);
            cb = ycbcrImg(:,:,2);
            cr = ycbcrImg(:,:,3);
        
            % Convert to rgb
            r = (255/219) * (y - 16) + (255/224) * 1.402 * (cr - 128);
            g = (255/219) * (y - 16) - (255/224) * 1.772 * (0.114/0.587) * (cb - 128) - (255/224) * 1.402 * (0.299/0.587) * (cr - 128);
            b = (255/219) * (y - 16) + (255/224) * 1.772 *(cb - 128);
        
            % Form the rgb image.
            rgbImg = uint8(cat(3, r, g, b));
        end

        % Does chroma subsampling.
        function sampledImg = chromaSubsampling(ycbcrImg, sampleFactor)
            Y = ycbcrImg(:,:,1);
            cb = ycbcrImg(:,:,2);
            cr = ycbcrImg(:,:,3);
            % Perform 4:2:0 chroma subsampling when sampleFactor == 0.5
            cbDownsampled = imresize(cb, sampleFactor, 'bilinear');
            crDownsampled = imresize(cr, sampleFactor, 'bilinear');
            % Resize back
            [M, N, ~] = size(Y);
            cbDownsampled = imresize(cbDownsampled, [M, N]);
            crDownsampled = imresize(crDownsampled, [M, N]);
            
            % Form the new ycbcr image.
            sampledImg = cat(3, Y, cbDownsampled, crDownsampled);
        end

        % Converts an image to k x k x 3 blocks
        function imgBlocks = img2blocks(img, k)
            rows = ceil(size(img, 1) / k);
            cols = ceil(size(img, 2) / k);

            % Pad the image to make dimensions multiples of k
            paddedImg = padarray(img, [rows * k - size(img, 1), cols * k - size(img, 2)], 'post');
        
            % Split the padded image into k x k x 3 blocks of rows x cols 
            imgBlocks = mat2cell(paddedImg, repmat(k, 1, rows), repmat(k, 1, cols), 3);
        end

        % Converts imgBlocks back to m x n x 3 img. Note that the resultant
        % image may be slightly larger than the original due to padding beforehand.
        function img = blocks2img(imgBlocks)
            img = cell2mat(imgBlocks);
        end

        % 2D FFT for each block and each channel.
        function fftImgBlocks = fft2d(imgBlocks)
            fftImgBlocks = cellfun(@fft2, imgBlocks, "UniformOutput", false);
        end

        % 2D inverse FFT for each block and each channel.
        function imgBlocks = ifft2d(fftImgBlocks)
            imgBlocks = cellfun(@ifft2, fftImgBlocks, "UniformOutput", false);
        end

        % Quantise values of each block and each channel
        function quantized = quantize(fftImgBlocks, k)
            q_table = [
                16, 11, 10, 16, 24, 40, 51, 61;
                12, 12, 14, 19, 26, 58, 60, 55;
                14, 13, 16, 24, 40, 57, 69, 56;
                14, 17, 22, 29, 51, 87, 80, 62;
                18, 22, 37, 56, 68, 109, 103, 77;
                24, 35, 55, 64, 81, 104, 113, 92;
                49, 64, 78, 87, 103, 121, 120, 101;
                72, 92, 95, 98, 112, 100, 103, 99
            ];
            q_table = kron(q_table, ones(k / 8));
            quantized = cellfun(@(c) c ./ q_table, fftImgBlocks, "UniformOutput", false);
            quantized = cellfun(@round, quantized, "UniformOutput", false);
        end

        % Get the unquantised values
        function fftImgBlocks = unquantize(quantized, k)
            q_table = [
                16, 11, 10, 16, 24, 40, 51, 61;
                12, 12, 14, 19, 26, 58, 60, 55;
                14, 13, 16, 24, 40, 57, 69, 56;
                14, 17, 22, 29, 51, 87, 80, 62;
                18, 22, 37, 56, 68, 109, 103, 77;
                24, 35, 55, 64, 81, 104, 113, 92;
                49, 64, 78, 87, 103, 121, 120, 101;
                72, 92, 95, 98, 112, 100, 103, 99
            ];
            q_table = kron(q_table, ones(k / 8));
            fftImgBlocks = cellfun(@(c) c .* q_table, quantized, "UniformOutput", false);
        end

        % Convert into 1d array
        function flat_array = flatten(quantized, k)
            flat_array = [size(quantized, 1), size(quantized, 2)];
            imag_flat = [];
            if k == 8
                scanning_order = load("scanning8.mat").scanning8;
            elseif k == 16
                scanning_order = load("scanning16.mat").scanning16;
            else
                scanning_order = load("scanning32.mat").scanning32;
            end

            for i = 1 : size(quantized, 1)
                for j = 1 : size(quantized, 2)
                    chans = cell2mat(quantized(i, j));
                    chans_real = real(chans);
                    chans_imag = imag(chans);
                    
                    flat_array = [flat_array chans_real(scanning_order) chans_real(scanning_order + k * k) chans_real(scanning_order + 2 * k * k)];
                    imag_flat = [imag_flat chans_imag(scanning_order) chans_imag(scanning_order + k * k ) chans_imag(scanning_order + 2 * k * k)];
                end
            end

            flat_array = [flat_array imag_flat];
        end

        % Convert a flattened array into the quantized matrix form
        function quantized = unflatten(flat_array, k)
            quantized = cell(flat_array(1), flat_array(2));
            flat_array = flat_array(3:end);
            imag_flat = flat_array(numel(flat_array) / 2 + 1 : end);
            flat_array = flat_array(1 : numel(flat_array) / 2);
            flat_array = flat_array + imag_flat * 1i;
            if k == 8
                scanning_order = load("scanning8.mat").scanning8;
            elseif k == 16
                scanning_order = load("scanning16.mat").scanning16;
            else
                scanning_order = load("scanning32.mat").scanning32;
            end

            scanning_order = [scanning_order scanning_order + k * k scanning_order + 2 * k * k];

            for m = 1 : size(quantized, 1)
                for n = 1 : size(quantized, 2)
                    cel = reshape(flat_array(1 : 3 * k * k), [k, k, 3]);
                    cel(scanning_order) = cel;
                    quantized(m, n) = num2cell(cel, [1 2 3]);
                    flat_array = flat_array(3 * k * k + 1 : end);
                end
            end

        end

        % Run length encode a 1-d array
        function encoded_array = rlencode(input_array)
            % Find the indices where the values of x change
            idx = find([true, diff(input_array) ~= 0]);

            % Compute the lengths of consecutive values
            len = diff([idx, numel(input_array) + 1]);

            % Compute the values of consecutive values
            val = input_array(idx);

            encoded_array = [len(:), val(:)].';
            encoded_array = encoded_array(:).';
        end

        % Run length decode a 1-d array
        function decoded_array = rldecode(input_array)
            lengths = input_array(1:2:length(input_array));
            symbols = input_array(2:2:length(input_array));
            decoded_array = repelem(symbols, lengths);
        end

        % Find frequency and do Huffman coding on an array
        function [encoded, code_book] = huffman_encode(input_matrix)
            % Convert matrix to vector and do run-length encode
            [C, ia, ic] = unique(input_matrix);
            freq = accumarray(ic, 1);
            freq = freq / numel(input_matrix);
            % Create huffman code and encode
            code_book = huffmandict(C, freq);
            encoded = huffmanenco(input_matrix, code_book);
        end

        function rlencoded = huffman_decode(encoded, code_book)
            rlencoded = huffmandeco(encoded, code_book);
        end

        function [compressedData, code_book] = compress(rgbImg, quality)
            if strcmp(quality, "low")
                sampleFactor = 0.25;
                blockSize = 32;
            elseif strcmp(quality, "med")
                sampleFactor = 0.5;
                blockSize = 16;
            else % high quality
                sampleFactor = 0.75;
                blockSize = 8;
            end

            % Step 1: Convert RGB to YCbCr
            ycbcrImg = myJPEG.rgb2ycbcr(rgbImg);

            % Step 2: Chroma subsample
            sampledImg = myJPEG.chromaSubsampling(ycbcrImg, sampleFactor);

            % Step 3: Block splitting
            imgBlocks = myJPEG.img2blocks(sampledImg, blockSize);

            % Step 4: 2d FFT on each block
            fftImgBlocks = myJPEG.fft2d(imgBlocks);

            % Step 5: Quantise the values
            
            quantized = myJPEG.quantize(fftImgBlocks, blockSize);

            % Step 6: Scan the values in zigzag

            flat_array = myJPEG.flatten(quantized, blockSize);

            % Step 7: Run-length and Huffman code
            encoded = myJPEG.rlencode(flat_array);
            [compressedData, code_book] = myJPEG.huffman_encode(encoded);
        end
        
        function finalImg = decompress(compressedData, code_book)
            % Step 1: Huffman and run-length decode
            encoded = myJPEG.huffman_decode(compressedData, code_book);
            flat_array = myJPEG.rldecode(encoded);

            % Step 2: Gather the values in zigzag manner
            quantized = myJPEG.unflatten(flat_array, 8);

            % Step 3: Unquantised the matrix
            fftImgBlocks = myJPEG.unquantize(quantized, 8);

            % Step 4: Inverse 2D FFT on each block.
            imgBlocks = myJPEG.ifft2d(fftImgBlocks);

            % Step 5: Convert blocks to ycbcr image
            ycbcrImg = myJPEG.blocks2img(imgBlocks);

            % Step 6: Convert YCbCr to RGB image
            finalImg = myJPEG.ycbcr2rgb(ycbcrImg);
        end
    end
end
