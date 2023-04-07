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

        function compressedData = compress(rgbImg, quality)
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

            % Step 5: Zigzag, quantize, huffman

            compressedData = fftImgBlocks;
        end
        
        function finalImg = decompress(compressedData)
            % Step 1: Huffman decode, dequantize, zigzag

            % Step 2: Inverse 2D FFT on each block.
            imgBlocks = myJPEG.ifft2d(compressedData);

            % Step 3: Convert blocks to ycbcr image
            ycbcrImg = myJPEG.blocks2img(imgBlocks);

            % Step 4: Convert YCbCr to RGB image
            finalImg = myJPEG.ycbcr2rgb(ycbcrImg);
        end
    end
end
