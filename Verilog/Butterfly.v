//----------------------------------------------------------------------
//  Butterfly: 加减并缩放的蝶形运算
//----------------------------------------------------------------------
// [通用] FFT/IFFT 的基本蝶形运算单元
module Butterfly #(
    parameter   WIDTH = 16,
    parameter   RH = 0  //  四舍五入控制位
)(
    input   signed  [WIDTH-1:0] x0_re,  //  输入数据0实部
    input   signed  [WIDTH-1:0] x0_im,  //  输入数据0虚部
    input   signed  [WIDTH-1:0] x1_re,  //  输入数据1实部
    input   signed  [WIDTH-1:0] x1_im,  //  输入数据1虚部
    output  signed  [WIDTH-1:0] y0_re,  //  输出数据0实部
    output  signed  [WIDTH-1:0] y0_im,  //  输出数据0虚部
    output  signed  [WIDTH-1:0] y1_re,  //  输出数据1实部
    output  signed  [WIDTH-1:0] y1_im   //  输出数据1虚部
);

// 四个内部信号用于存放加法和减法结果
wire signed [WIDTH:0]   add_re, add_im, sub_re, sub_im;

//  加法与减法运算
assign  add_re = x0_re + x1_re;
assign  add_im = x0_im + x1_im;
assign  sub_re = x0_re - x1_re;
assign  sub_im = x0_im - x1_im;

//  结果缩放，右移一位等效于除以 2
assign  y0_re = (add_re + RH) >>> 1;
assign  y0_im = (add_im + RH) >>> 1;
assign  y1_re = (sub_re + RH) >>> 1;
assign  y1_im = (sub_im + RH) >>> 1;

endmodule
