quantization_table = [
    16, 11, 10, 16, 24, 40, 51, 61;
    12, 12, 14, 19, 26, 58, 60, 55;
    14, 13, 16, 24, 40, 57, 69, 56;
    14, 17, 22, 29, 51, 87, 80, 62;
    18, 22, 37, 56, 68, 109, 103, 77;
    24, 35, 55, 64, 81, 104, 113, 92;
    49, 64, 78, 87, 103, 121, 120, 101;
    72, 92, 95, 98, 112, 100, 103, 99
];

function quantized = quantize(input_matrix, k)
    qt_reshaped = reshape(quantization_table, [1, 1, k, k]);
    quantized = bsxfun(@rdivide, input_matrix, qt_reshaped);
    quantized = round(quantized);
end

function unquantized = reverse_quantize(quantized, k)
    qt_reshaped = reshape(quantization_table, [1, 1, k, k]);
    unquantized = bsxfun(@times, quantized, qt_reshaped);
end
