clc; clear;

%% 1. 原图像转比特流
img = imread('C:\Users\huang\Desktop\test.jpg');
SNR_dB_range = 0:2:30;
ber_result = zeros(size(SNR_dB_range));

img_bits = de2bi(img(:), 8, 'left-msb');
bit_stream = img_bits'; bit_stream = bit_stream(:);

%% 2. QAM调制
bit_per_symbol = 4;
num_symbols = ceil(length(bit_stream)/bit_per_symbol);
pad_len = num_symbols*bit_per_symbol - length(bit_stream);
bit_stream = [bit_stream; zeros(pad_len, 1)];
bit_groups = reshape(bit_stream, bit_per_symbol, [])';

qam_map = [ -3 -3; -1 -3; -3 -1; -1 -1;
             3 -3;  1 -3;  3 -1;  1 -1;
            -3  3; -1  3; -3  1; -1  1;
             3  3;  1  3;  3  1;  1  1 ];
sym_idx = bi2de(bit_groups, 'left-msb')+1;
symbols = qam_map(sym_idx,1) + 1j * qam_map(sym_idx,2);

%% 3. OFDM参数
Nfft = 1024; cp_len = Nfft/8;
num_ofdm_sym = ceil(length(symbols)/Nfft);
pad_symbols = num_ofdm_sym*Nfft - length(symbols);
symbols = [symbols; zeros(pad_symbols,1)];
ofdm_matrix = reshape(symbols, Nfft, []);
ofdm_time = ifft(ofdm_matrix, Nfft);
ofdm_cp = [ofdm_time(end-cp_len+1:end,:); ofdm_time];
ofdm_serial = ofdm_cp(:);

%% 4. 上变频 + 带通滤波
fs = 10e6; fc = 2e6; Ts = 1/fs;
t = (0:length(ofdm_serial)-1)' * Ts;
I = real(ofdm_serial); Q = imag(ofdm_serial);
tx_rf = I .* cos(2*pi*fc*t) - Q .* sin(2*pi*fc*t);

bpFilt = designfilt('bandpassfir', ...
    'StopbandFrequency1', fc*0.4, ...
    'PassbandFrequency1', fc*0.8, ...
    'PassbandFrequency2', fc*1.2, ...
    'StopbandFrequency2', fc*1.6, ...
    'SampleRate', fs, 'DesignMethod','equiripple');

tx_rf_filtered = filter(bpFilt, tx_rf);

%% 5. 信道 + 下变频 + 低通滤波
lpFilt = designfilt('lowpassfir', ...
    'PassbandFrequency', 1.5e6, ...
    'StopbandFrequency', 2.5e6, ...
    'SampleRate', fs, 'DesignMethod','equiripple');

for k = 1:length(SNR_dB_range)
    SNR_dB = SNR_dB_range(k);
    rx_rf = awgn(tx_rf_filtered, SNR_dB, 'measured');

    rx_I = rx_rf .* cos(2*pi*fc*t);
    rx_Q = rx_rf .* sin(2*pi*fc*t);
    rx_bb = (rx_I + 1j * rx_Q) / 2;

    rx_bb_filt = filter(lpFilt, rx_bb);

    rx_matrix = reshape(rx_bb_filt, Nfft+cp_len, []);
    rx_no_cp = rx_matrix(cp_len+1:end,:);
    rx_fft = fft(rx_no_cp, Nfft);
    rx_symbols = rx_fft(:);
    rx_symbols = rx_symbols(1:end - pad_symbols);

    %% 判决
    ref = qam_map(:,1) + 1j * qam_map(:,2);
    rx_bits = zeros(length(rx_symbols), 4);
    for i = 1:length(rx_symbols)
        [~, idx] = min(abs(rx_symbols(i) - ref));
        rx_bits(i,:) = de2bi(idx-1, 4, 'left-msb');
    end
    rx_bitstream = reshape(rx_bits.',[],1);
    rx_bitstream = rx_bitstream(1:end-pad_len);
    ber_result(k) = sum(bit_stream ~= rx_bitstream) / length(bit_stream);
end

%% 6. 图像恢复与绘图
rx_pixels = bi2de(reshape(rx_bitstream,8,[]).','left-msb');
rx_img = reshape(rx_pixels, size(img));

figure('Name','OFDM图像传输系统（带上下变频）','NumberTitle','off');
subplot(2,2,1);
semilogy(SNR_dB_range, ber_result, 'o-','LineWidth',2);
xlabel('SNR (dB)'); ylabel('BER'); title('BER vs SNR'); grid on;

subplot(2,2,2);
scatter(real(rx_symbols), imag(rx_symbols), 'filled'); axis square; grid on;
title('接收星座图');

subplot(2,2,3); imshow(img); title('原图');
subplot(2,2,4); imshow(uint8(rx_img));
title(['恢复图像 BER = ' num2str(ber_result(end),'%.6f')]);
