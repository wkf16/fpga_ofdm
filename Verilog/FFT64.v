//----------------------------------------------------------------------
//  FFT: 基于 Radix-2^2 SDF 的 64 点 FFT
//----------------------------------------------------------------------
// [RX] 64 点 FFT 模块，IFFT64 也会复用
module FFT64 #(parameter WIDTH = 16) (
                 input                clock,  // 主时钟
                 input                reset,  //  异步复位
                 input                di_en,  //  输入使能
                 input   [WIDTH-1:0]  di_re,  //  输入实部
                 input   [WIDTH-1:0]  di_im,  //  输入虚部
                 output               do_en,  //  输出使能
                 output  [WIDTH-1:0]  do_re,  //  输出实部
                 output  [WIDTH-1:0]  do_im   //  输出虚部
	);
        //----------------------------------------------------------------------
        //  输入数据需按照自然顺序连续送入
        //  结果会自动缩放 1/N 并以倒位序输出
        //  输出延迟共计 71 个时钟周期
        //----------------------------------------------------------------------

	wire             su1_do_en;
	wire [WIDTH-1:0] su1_do_re;
	wire [WIDTH-1:0] su1_do_im;
	wire             su2_do_en;
	wire [WIDTH-1:0] su2_do_re;
	wire [WIDTH-1:0] su2_do_im;

        SdfUnit #(.N(64), .M(64), .WIDTH(WIDTH)) SU1 (
                 .clock  (clock    ),  //  时钟
                 .reset  (reset    ),  //  复位
                 .di_en  (di_en    ),  //  输入使能
                 .di_re  (di_re    ),  //  输入实部
                 .di_im  (di_im    ),  //  输入虚部
                 .do_en  (su1_do_en),  //  输出使能
                 .do_re  (su1_do_re),  //  输出实部
                 .do_im  (su1_do_im)   //  输出虚部
        );

        SdfUnit #(.N(64), .M(16), .WIDTH(WIDTH)) SU2 (
                 .clock  (clock    ),  //  时钟
                 .reset  (reset    ),  //  复位
                 .di_en  (su1_do_en),  //  上级输出使能
                 .di_re  (su1_do_re),  //  上级输出实部
                 .di_im  (su1_do_im),  //  上级输出虚部
                 .do_en  (su2_do_en),  //  输出使能
                 .do_re  (su2_do_re),  //  输出实部
                 .do_im  (su2_do_im)   //  输出虚部
        );

        SdfUnit #(.N(64), .M(4), .WIDTH(WIDTH)) SU3 (
                 .clock  (clock    ),  //  时钟
                 .reset  (reset    ),  //  复位
                 .di_en  (su2_do_en),  //  上级输出使能
                 .di_re  (su2_do_re),  //  上级输出实部
                 .di_im  (su2_do_im),  //  上级输出虚部
                 .do_en  (do_en    ),  //  输出使能
                 .do_re  (do_re    ),  //  输出实部
                 .do_im  (do_im    )   //  输出虚部
        );

endmodule
