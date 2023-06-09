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

        % Pad the image to make dimensions multiples of k
        function paddedImg = padImage(img, k)
            rows = ceil(size(img, 1) / k);
            cols = ceil(size(img, 2) / k);

            paddedImg = padarray(img, [rows * k - size(img, 1), cols * k - size(img, 2)], 255, 'post');
        end

        % Converts an image to k x k x 3 blocks
        function imgBlocks = img2blocks(paddedImg, k)
            rows = size(paddedImg, 1) / k;
            cols = size(paddedImg, 2) / k;
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
                24, 28, 40, 56, 56, 40, 28, 24;
                28, 34, 64, 99, 99, 64, 34, 28;
                38, 63, 99, 129, 129, 99, 63, 38;
                52, 99, 129, 119, 119, 129, 99, 52;
                52, 99, 129, 119, 119, 129, 99, 52;
                38, 63, 99, 129, 129, 99, 63, 38;
                28, 34, 64, 99, 99, 64, 34, 28;
                24, 28, 40, 56, 56, 40, 28, 24;
            ];
            q_table = kron(q_table, ones(k / 8));
            quantized = cellfun(@(c) c ./ q_table, fftImgBlocks, "UniformOutput", false);
            quantized = cellfun(@round, quantized, "UniformOutput", false);
        end

        % Get the unquantised values
        function fftImgBlocks = unquantize(quantized, k)
            q_table = [
                24, 28, 40, 56, 56, 40, 28, 24;
                28, 34, 64, 99, 99, 64, 34, 28;
                38, 63, 99, 129, 129, 99, 63, 38;
                52, 99, 129, 119, 119, 129, 99, 52;
                52, 99, 129, 119, 119, 129, 99, 52;
                38, 63, 99, 129, 129, 99, 63, 38;
                28, 34, 64, 99, 99, 64, 34, 28;
                24, 28, 40, 56, 56, 40, 28, 24;
            ];
            q_table = kron(q_table, ones(k / 8));
            fftImgBlocks = cellfun(@(c) c .* q_table, quantized, "UniformOutput", false);
        end

        % Convert into 1d array
        function flat_array = flatten(quantized, k)
            % Store size of matrix as first 2 elements
            flat_array = [size(quantized, 1), size(quantized, 2)];

            if k == 8
                scanning_order = load("scanning8.mat").scanning8;
            elseif k == 16
                scanning_order = load("scanning16.mat").scanning16;
            else
                scanning_order = load("scanning32.mat").scanning32;
            end

            % Define function to scan each cell
            scan = @(x) [x(scanning_order) x(scanning_order + k*k) x(scanning_order + 2*k*k)];
    
            intermediate = cellfun(scan, quantized, 'UniformOutput', false);
            intermediate = cell2mat(reshape(intermediate, 1, []));
            flat_array = cat(2, flat_array, real(intermediate), imag(intermediate));
            flat_array = int16(flat_array);
        end

        % Convert a flattened array into the quantized matrix form
        function quantized = unflatten(flat_array, k)
            % Get size of matrix from first 2 elements
            s1 = flat_array(1);
            s2 = flat_array(2);
            flat_array = flat_array(3:end);
            % Split and sum the real and imaginary parts
            imag_flat = flat_array(numel(flat_array) / 2 + 1 : end);
            flat_array = flat_array(1 : numel(flat_array) / 2);
            flat_array = double(flat_array) + double(imag_flat) .* 1i;

            if k == 8
                scanning_order = load("scanning8.mat").scanning8;
            elseif k == 16
                scanning_order = load("scanning16.mat").scanning16;
            else
                scanning_order = load("scanning32.mat").scanning32;
            end

            scanning_order = [scanning_order scanning_order + k * k scanning_order + 2 * k * k];
            flat_array = reshape(flat_array, k*k*3, []);
            flat_array(scanning_order, :) = flat_array;
            flat_array = reshape(flat_array, [k, k, 3, s1, s2]);
            flat_array = permute(flat_array, [4 5 1 2 3]);
            quantized = num2cell(flat_array, [3 4 5]);
            quantized = cellfun(@squeeze, quantized, 'UniformOutput', false);
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
            % Count frequencies
            [C, ~, ic] = unique(input_matrix);
            freq = accumarray(ic, 1);
            freq = freq / numel(input_matrix);
            % Create huffman code and encode
            code_book = huffmandict(C, freq);

            % Huffman encode matrix in parts to avoid too large matrices
            chunk_size = ceil(2e9 / size(C, 2));
            chunks = mat2cell(input_matrix, 1, [chunk_size * ones(1, floor(numel(input_matrix) / chunk_size)) mod(numel(input_matrix), chunk_size)]);
            encoded = cellfun(@(c) huffmanenco(c, code_book), chunks, "UniformOutput", false);
            encoded = cell2mat(encoded);
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

            % Step 1: Pad image to fit block size of k x k
            paddedImg = myJPEG.padImage(rgbImg, blockSize);

            % Step 2: Convert RGB to YCbCr
            ycbcrImg = myJPEG.rgb2ycbcr(paddedImg);

            % Step 3: Chroma subsample
            sampledImg = myJPEG.chromaSubsampling(ycbcrImg, sampleFactor);

            % Step 4: Block splitting
            imgBlocks = myJPEG.img2blocks(sampledImg, blockSize);

            % Step 5: 2d FFT on each block
            fftImgBlocks = myJPEG.fft2d(imgBlocks);

            % Step 6: Quantise the values
            quantized = myJPEG.quantize(fftImgBlocks, blockSize);

            % Step 7: Scan the values in zigzag
            flat_array = myJPEG.flatten(quantized, blockSize);

            % Step 8: Huffman code and run-length encode
            encoded = myJPEG.rlencode(flat_array);
            [compressedData, code_book] = myJPEG.huffman_encode(encoded);
        end
        
        function finalImg = decompress(compressedData, code_book, quality)
            if strcmp(quality, "low")
                blockSize = 32;
            elseif strcmp(quality, "med")
                blockSize = 16;
            else % high quality
                blockSize = 8;
            end

            % Step 1: Huffman and run-length decode
            encoded = myJPEG.huffman_decode(compressedData, code_book);
            flat_array = myJPEG.rldecode(encoded);

            % Step 2: Gather the values in zigzag manner
            quantized = myJPEG.unflatten(flat_array, blockSize);

            % Step 3: Unquantised the matrix
            fftImgBlocks = myJPEG.unquantize(quantized, blockSize);

            % Step 4: Inverse 2D FFT on each block.
            imgBlocks = myJPEG.ifft2d(fftImgBlocks);

            % Step 5: Convert blocks to ycbcr image
            ycbcrImg = myJPEG.blocks2img(imgBlocks);

            % Step 6: Convert YCbCr to RGB image
            finalImg = myJPEG.ycbcr2rgb(ycbcrImg);
        end
    end
end
