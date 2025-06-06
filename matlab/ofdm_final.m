% 读入图片
img = imread('C:\\Users\\huang\\Desktop\\test.jpg'); 

SNR_dB_range = 0:2:30;  % 从0到30dB，每隔2dB
ber_result = zeros(size(SNR_dB_range));  % 存放对应BER

% 图片转为比特流
img_bits = de2bi(img(:),8,'left-msb'); % 每像素8bit，RGB三个通道
bit_stream = img_bits';
bit_stream = bit_stream(:); % 变成列向量






% 16QAM调制
bit_per_symbol = 4; % 16QAM
num_symbols = ceil(length(bit_stream)/bit_per_symbol);
pad_length = num_symbols*bit_per_symbol - length(bit_stream);
bit_stream = [bit_stream; zeros(pad_length,1)]; % 补0对齐

% 分组4bit一组
bits_reshaped = reshape(bit_stream, bit_per_symbol, []).';

% Gray编码映射16QAM
symbol_map = [ -3 -3; -1 -3; -3 -1; -1 -1;
               +3 -3; +1 -3; +3 -1; +1 -1;
              -3 +3; -1 +3; -3 +1; -1 +1;
              +3 +3; +1 +3; +3 +1; +1 +1 ];

symbol_idx = bi2de(bits_reshaped,'left-msb')+1; 
symbols = symbol_map(symbol_idx,1) + 1j*symbol_map(symbol_idx,2);

% OFDM参数
Nfft = 1024; % IFFT/FFT点数
cp_len = Nfft/8; % 循环前缀长度，假设为1/8

% 按每Nfft个子载波分帧
num_ofdm_symbols = ceil(length(symbols)/Nfft);
pad_symbols = num_ofdm_symbols*Nfft - length(symbols);
symbols = [symbols; zeros(pad_symbols,1)];
symbols_matrix = reshape(symbols, Nfft, []);

% IFFT + 加循环前缀
ofdm_time = ifft(symbols_matrix, Nfft);
ofdm_cp = [ofdm_time(end-cp_len+1:end,:); ofdm_time];
ofdm_serial = ofdm_cp(:); % 串行发送信号

% 加噪声（AWGN信道）
for snr_idx = 1:length(SNR_dB_range)
    SNR_dB = SNR_dB_range(snr_idx);

rx_serial = awgn(ofdm_serial, SNR_dB, 'measured');

% 串行转并行
rx_cp_matrix = reshape(rx_serial, Nfft+cp_len, []);

% 去除循环前缀
rx_matrix = rx_cp_matrix(cp_len+1:end, :);

% FFT
rx_symbols_matrix = fft(rx_matrix, Nfft);
rx_symbols = rx_symbols_matrix(:);

% 16QAM解调（使用最小距离判决，严格对应Gray编码）
rx_symbols = rx_symbols(1:end-pad_symbols); % 去0
symbol_map_complex = symbol_map(:,1) + 1j*symbol_map(:,2);

% 解调：最小欧氏距离判决
rx_bits = zeros(length(rx_symbols), 4);
for k = 1:length(rx_symbols)
    [~, idx] = min(abs(rx_symbols(k) - symbol_map_complex));
    rx_bits(k,:) = de2bi(idx-1, 4, 'left-msb');
end

rx_bitstream = reshape(rx_bits.',[],1);
rx_bitstream = rx_bitstream(1:end-pad_length); % 去0
ber = sum(abs(double(rx_bitstream)-double(bit_stream)))/length(bit_stream);
    ber_result(snr_idx) = ber;
end

% 恢复图片
rx_pixels = bi2de(reshape(rx_bitstream,8,[]).','left-msb');
rx_img = reshape(rx_pixels, size(img));

% 补充子图：时域发送波形（进信道前）
figure('Name','OFDM调制后时域信号','NumberTitle','off');
t = (1:length(ofdm_serial)) / Nfft;  % 归一化时间

subplot(2,1,1);
plot(t, real(ofdm_serial));
title('OFDM串行发送信号 - 实部');
xlabel('时间');
ylabel('幅度');
grid on;

subplot(2,1,2);
plot(t, imag(ofdm_serial));
title('OFDM串行发送信号 - 虚部');
xlabel('时间');
ylabel('幅度');
grid on;




% 画图
figure('Name','OFDM图像传输','NumberTitle','off');

% BER vs SNR图
subplot(2,2,1);
semilogy(SNR_dB_range, ber_result, 'o-','LineWidth',2);
grid on;
xlabel('SNR (dB)');
ylabel('Bit Error Rate (BER)');
title('BER vs SNR 曲线 (16QAM-OFDM)');

% 接收星座图
rx_symbols_valid = rx_symbols(1:end-pad_symbols);
subplot(2,2,2);
scatter(real(rx_symbols_valid), imag(rx_symbols_valid), 'filled');
title('接收端星座图');
xlabel('In-phase');
ylabel('Quadrature');
grid on;
axis square;

% 原始图像
subplot(2,2,3);
imshow(img);
title('原始图片');

% 恢复图像
subplot(2,2,4);
imshow(uint8(rx_img));
title({'接收恢复图片', ['BER = ', num2str(ber, '%.6f')]});







