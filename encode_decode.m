function encoded, code_book = huffman_encode(input_matrix)
    % Convert matrix to vector and do run-length encode
    flat_array = flatten(matrix);
    encoded_array = rlencode(flat_array);
    % Count occurrence of symbols
    [C, ia, ic] = unique(encoded_array);
    freq = accumarray(ic, 1);
    freq = freq / numel(encoded_array);
    % Create huffman code and encode
    code_book = huffmandict(C, freq);
    encoded = huffmanenco(encoded_array, code_book);
end

function quantized_matrix = huffman_decode(encoded, code_book)
    decoded = huffmandeco(encoded, code_book);
    decoded = rldecode(decoded);
end

function flat_array = flatten(matrix, k)
    flat_array = [size(matrix, 1), size(matrix, 2)];
    if k == 8
        scanning_order = load("scanning8.mat");
    elseif k == 16
        scanning_order = load("scanning16.mat");
    else
        scanning_order = load("scanning32.mat");
    end

    for i = 1 : size(matrix, 1)
        for j = 1 : size(matrix, 2)
            flat_array = [flat_array quantized_matrices(i, j, scanning_order)];
        end
    end
end

function matrix = unflatten(flat_array, k)
    matrix = zeros(flat_array(1), flat_array(2), k, k)
    flat_array = flat_array(3:end)
    if k == 8
        scanning_order = load("scanning8.mat");
    elseif k == 16
        scanning_order = load("scanning16.mat");
    else
        scanning_order = load("scanning32.mat");
    end

    for i = 1 : size(matrix, 1)
        for j = 1 : size(matrix, 2)
            matrix(i, j, scanning_order) = flat_array(1 : k * k);
            flat_array = flat_array(k * k + 1 : end);
        end
    end
end


function encoded_array = rlencode(input_array)
    % Find the indices where the values of x change
    idx = find([true, diff(input_array) ~= 0]);

    % Compute the lengths of consecutive values
    len = diff([0, idx, numel(input_array) + 1]) - 1;

    % Compute the values of consecutive values
    val = input_array(idx);

    encoded_array = [len(:), val(:)].';
end

function decoded_array = rldecode(input_array)
    lengths = input_array(1:2:length(input_array));
    symbols = input_array(2:2:length(input_array));
    decoded_array = repelem(symbols, lengths);
end

