//----------------------------------------------------------------------
//  DelayBuffer: 产生固定时钟周期延迟
//----------------------------------------------------------------------
// [通用] 固定长度延时线
module DelayBuffer #(
    parameter   DEPTH = 32, // 缓冲深度
    parameter   WIDTH = 16  // 数据宽度
)(
    input               clock,  // 主时钟
    input   [WIDTH-1:0] di_re,  // 输入实部
    input   [WIDTH-1:0] di_im,  // 输入虚部
    output  [WIDTH-1:0] do_re,  // 输出实部
    output  [WIDTH-1:0] do_im   // 输出虚部
);

// 延时缓冲区
reg [WIDTH-1:0] buf_re[0:DEPTH-1];
reg [WIDTH-1:0] buf_im[0:DEPTH-1];
integer n;

//  移位寄存器实现延迟
always @(posedge clock) begin
    for (n = DEPTH-1; n > 0; n = n - 1) begin
        buf_re[n] <= buf_re[n-1];
        buf_im[n] <= buf_im[n-1];
    end
    buf_re[0] <= di_re;
    buf_im[0] <= di_im;
end

assign  do_re = buf_re[DEPTH-1];
assign  do_im = buf_im[DEPTH-1];

endmodule
