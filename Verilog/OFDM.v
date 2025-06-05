//----------------------------------------------------------------------
//  OFDM: 顶层收发模块
//----------------------------------------------------------------------
// [顶层] OFDM 收发器，整合 TX 与 RX
module OFDM (
    input clk,           // 系统时钟
    input reset,         // 异步复位
    input x_in,          // 待发送的比特流
    output [3:0] x_out   // 解调后的输出比特
);


reg clk_half;  // 生成分频时钟（示例）

// 负边沿产生一半频率的时钟，复位时置高
always @(negedge clk or posedge reset) begin
    if (reset) begin
        clk_half <= 1;          // 复位输出 1
    end else begin
        clk_half <= ~clk_half;  // 每个时钟翻转一次
    end
end


wire encoder_out;   // 编码后的比特
wire encoder_esig;  // 编码器使能信号

// 卷积编码器
Encoder encoder1(
    .clk(clk),            // 时钟
    .reset(reset),        // 复位
    .in(x_in),            // 输入比特
    .out(encoder_out),    // 编码结果
    .out_esig(encoder_esig) // 输出使能
);

wire mod_en;                 // 调制器输出使能
wire signed [15:0] mod_outx; // QPSK I 分量
wire signed [15:0] mod_outy; // QPSK Q 分量

// QPSK 调制器
Mod mod1(
    .clk(clk),                // 时钟
    .reset(reset),            // 复位
    .en(mod_en),              // 输出使能
    .encoder_en(encoder_esig),// 编码完成指示
    .in(encoder_out),         // 输入比特
    .outx(mod_outx),          // I 分量
    .outy(mod_outy)           // Q 分量
);


wire ifft_en;                     // IFFT 输出使能
wire signed [15:0] ifft_out_re;   // IFFT 输出实部
wire signed [15:0] ifft_out_im;   // IFFT 输出虚部

reg always_en;  // 预留控制信号
always @(posedge clk) begin
    if (reset)
        always_en <= 0;           // 复位清零
end

always @(*) begin
    if (mod_en == 1'b1)
        always_en <= 1'b1;        // 当调制完成后一直保持使能
end

wire reg_out_en;                  // 寄存器输出使能
wire signed [15:0] reg_out_x;     // 缓存 I 分量
wire signed [15:0] reg_out_y;     // 缓存 Q 分量

// 发送侧缓冲 64 个调制符号
FFT_Register fft_register1(
    .clk(clk),           // 时钟
    .reset(reset),       // 复位
    .inx(mod_outx),      // 输入 I 分量
    .iny(mod_outy),      // 输入 Q 分量
    .mod_en(mod_en),     // 输入使能
    .out_en(reg_out_en), // 输出使能
    .outx(reg_out_x),    // 输出 I 分量
    .outy(reg_out_y)     // 输出 Q 分量
);


// 发送端 64 点 IFFT
IFFT64 ifft1(
    .clock(clk),        // 时钟
    .reset(reset),      // 复位
    .di_en(reg_out_en), // 输入使能
    .di_re(reg_out_x),  // 输入实部
    .di_im(reg_out_y),  // 输入虚部
    .do_en(ifft_en),    // 输出使能
    .do_re(ifft_out_re),// 输出实部
    .do_im(ifft_out_im) // 输出虚部
);

// wire [15:0] cp_out_re,cp_out_im;
// wire cp_en;
// CP_test CP_test1(
//     .sysclk(clk),
//     .RST_I(reset),
//     .DAT1_I_r(ifft_out_re),
//     .DAT1_I_i(ifft_out_im),
//     .ACK_I(ifft_en),
//     .DAT2_O_r(cp_out_re),
//     .DAT2_O_i(cp_out_im),
//     .ACK_O(cp_en)
// );


// wire fft_en;
// wire [15:0] fft_out_re, fft_out_im;

// FFT64 fft1(
//     .clock(clk),
//     .reset(reset),
//     .di_en(cp_en),
//     .di_re(cp_out_re),
//     .di_im(cp_out_im),
//     .do_en(fft_en),
//     .do_re(fft_out_re),
//     .do_im(fft_out_im)
// );

wire fft_en;                         // FFT 输出使能
wire [15:0] fft_out_re, fft_out_im; // FFT 输出

// 接收端 64 点 FFT
FFT64 fft1(
    .clock(clk),        // 时钟
    .reset(reset),      // 复位
    .di_en(ifft_en),    // 输入使能
    .di_re(ifft_out_re),// 输入实部
    .di_im(ifft_out_im),// 输入虚部
    .do_en(fft_en),     // 输出使能
    .do_re(fft_out_re), // 输出实部
    .do_im(fft_out_im)  // 输出虚部
);



wire demod_en;           // 解调输出使能
wire [1:0] demod_out;    // 解调得到的符号
// QPSK 解调器
De_Mod deMod1(
    .clk(clk),        // 时钟
    .reset(reset),    // 复位
    .fft_en(fft_en),  // FFT 完成标志
    .inx(fft_out_im), // 输入虚部
    .iny(fft_out_re), // 输入实部
    .out(demod_out),  // 解调结果
    .en(demod_en)     // 输出使能
);




// 卷积解码器，得到最终比特流
Decoder decoder1(
    .clk(clk),           // 时钟
    .reset(reset),       // 复位
    .in(demod_out),      // 解调后的符号
    .demod_en(demod_en), // 使能
    .out(x_out)          // 输出比特
);



endmodule
