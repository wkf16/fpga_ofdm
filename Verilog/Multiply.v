//----------------------------------------------------------------------
//  Multiply: 复数乘法模块
//----------------------------------------------------------------------
// [通用] 用于 FFT/IFFT 的复数乘法器
module Multiply #(
    parameter   WIDTH = 16
)(
    input   signed  [WIDTH-1:0] a_re, // 输入复数 A 的实部
    input   signed  [WIDTH-1:0] a_im, // 输入复数 A 的虚部
    input   signed  [WIDTH-1:0] b_re, // 输入复数 B 的实部
    input   signed  [WIDTH-1:0] b_im, // 输入复数 B 的虚部
    output  signed  [WIDTH-1:0] m_re, // 结果实部
    output  signed  [WIDTH-1:0] m_im  // 结果虚部
);

// 内部乘法结果
wire signed [WIDTH*2-1:0]   arbr, arbi, aibr, aibi;
// 缩放后的乘法结果
wire signed [WIDTH-1:0]     sc_arbr, sc_arbi, sc_aibr, sc_aibi;

//  有符号乘法运算
assign  arbr = a_re * b_re;
assign  arbi = a_re * b_im;
assign  aibr = a_im * b_re;
assign  aibi = a_im * b_im;

//  结果缩放，右移 WIDTH-1 位保持数值范围
assign  sc_arbr = arbr >>> (WIDTH-1);
assign  sc_arbi = arbi >>> (WIDTH-1);
assign  sc_aibr = aibr >>> (WIDTH-1);
assign  sc_aibi = aibi >>> (WIDTH-1);

//  复数结果相减相加
//  若输入未归一化，此处可能溢出
assign  m_re = sc_arbr - sc_aibi;
assign  m_im = sc_arbi + sc_aibr;

endmodule
