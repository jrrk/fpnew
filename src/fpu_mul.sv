/////////////////////////////////////////////////////////////////////
////                                                             ////
////  FPU                                                        ////
////  Floating Point Unit (Double precision)                     ////
////                                                             ////
////  Author: David Lundgren                                     ////
////          davidklun@gmail.com                                ////
////                                                             ////
/////////////////////////////////////////////////////////////////////
////                                                             ////
//// Copyright (C) 2009 David Lundgren                           ////
////                  davidklun@gmail.com                        ////
////                                                             ////
//// This source file may be used and distributed without        ////
//// restriction provided that this copyright statement is not   ////
//// removed from the file and that any derivative work contains ////
//// the original copyright notice and the associated disclaimer.////
////                                                             ////
////     THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY     ////
//// EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED   ////
//// TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS   ////
//// FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL THE AUTHOR      ////
//// OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,         ////
//// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES    ////
//// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE   ////
//// GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR        ////
//// BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF  ////
//// LIABILITY, WHETHER IN  CONTRACT, STRICT LIABILITY, OR TORT  ////
//// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT  ////
//// OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE         ////
//// POSSIBILITY OF SUCH DAMAGE.                                 ////
////                                                             ////
/////////////////////////////////////////////////////////////////////


`timescale 1ns / 100ps

module fpu_mul(
 input             clk,
 input             rst,
 input             enable,
 input [63:0]      opa, opb,
 output reg        sign,
 output [55:0]     product_7,
 output reg [11:0] exponent_5,
 output reg        shift_inexact);

reg [5:0] 	product_shift;
reg [5:0] 	product_shift_2;

reg   [51:0] mantissa_a;
reg   [51:0] mantissa_b;
reg   [10:0] exponent_a;
reg   [10:0] exponent_b;
reg		a_is_norm;
reg		b_is_norm;
reg		a_is_zero; 
reg		b_is_zero; 
reg		in_zero;
reg   [11:0] exponent_terms;
reg    exponent_gt_expoffset;
reg   [11:0] exponent_under;
reg   [11:0] exponent_1;
wire   [11:0] exponent = 0;
reg   [11:0] exponent_2;
reg   exponent_gt_prodshift;
reg   [11:0] exponent_3;
reg   [11:0] exponent_4;
reg  exponent_et_zero;
reg   [52:0] mul_a;
reg   [52:0] mul_b;
reg		[40:0] product_a;
reg		[40:0] product_b;
reg		[40:0] product_c;
reg		[25:0] product_d;
reg		[33:0] product_e;
reg		[33:0] product_f;
reg		[35:0] product_g;
reg		[28:0] product_h;
reg		[28:0] product_i;
reg		[30:0] product_j;
reg		[41:0] sum_0;
reg		[35:0] sum_1;
reg		[41:0] sum_2;
reg		[35:0] sum_3;
reg		[36:0] sum_4;
reg		[27:0] sum_5;
reg		[29:0] sum_6;
reg		[36:0] sum_7;
reg		[30:0] sum_8;
reg   [105:0] product;
reg   [105:0] product_1;
reg   [105:0] product_2;
reg   [105:0] product_3;
reg   [105:0] product_4; 
reg   [105:0] product_5;
reg   [105:0] product_6;
reg		product_lsb; // if there are any 1's in the remainder
assign product_7 =  { 1'b0, product_6[105:52], product_lsb }; 

always @(posedge clk) 
begin
	if (rst) begin
		sign <= 0;
		mantissa_a <= 0;
		mantissa_b <= 0;
		exponent_a <= 0;
		exponent_b <= 0;
		a_is_norm <= 0;
		b_is_norm <= 0;
		a_is_zero <= 0; 
		b_is_zero <= 0; 
		in_zero <= 0;
		exponent_terms <= 0;
		exponent_gt_expoffset <= 0;
		exponent_under <= 0;
		exponent_1 <= 0; 
		exponent_2 <= 0;
		exponent_gt_prodshift <= 0;
		exponent_3 <= 0;
		exponent_4 <= 0;
		exponent_et_zero <= 0;
		mul_a <= 0; 
		mul_b <= 0;
		product_a <= 0;
		product_b <= 0;
		product_c <= 0;
		product_d <= 0;
		product_e <= 0;
		product_f <= 0;
		product_g <= 0;
		product_h <= 0;
		product_i <= 0;
		product_j <= 0;
		sum_0 <= 0;
		sum_1 <= 0;
		sum_2 <= 0;
		sum_3 <= 0;
		sum_4 <= 0;
		sum_5 <= 0;
		sum_6 <= 0;
		sum_7 <= 0;
		sum_8 <= 0;
		product <= 0;
		product_1 <= 0;
		product_2 <= 0; 
		product_3 <= 0;
		product_4 <= 0;
		product_5 <= 0; 
		product_6 <= 0;
		product_lsb <= 0;
		exponent_5 <= 0;
		product_shift_2 <= 0;
                shift_inexact <= 0;
	end
	else if (enable) begin
		sign <= opa[63] ^ opb[63];
		mantissa_a <= opa[51:0];
		mantissa_b <= opb[51:0];
		exponent_a <= opa[62:52];
		exponent_b <= opb[62:52];
		a_is_norm <= |exponent_a;
		b_is_norm <= |exponent_b;
		a_is_zero <= !(|opa[62:0]); 
		b_is_zero <= !(|opb[62:0]); 
		in_zero <= a_is_zero | b_is_zero;
		exponent_terms <= exponent_a + exponent_b + !a_is_norm + !b_is_norm;
		exponent_gt_expoffset <= exponent_terms > 1021;
		exponent_under <= 1022 - exponent_terms;
		exponent_1 <= exponent_terms - 1022; 
		exponent_2 <= exponent_gt_expoffset ? exponent_1 : exponent;
		exponent_gt_prodshift <= exponent_2 > product_shift_2;
		exponent_3 <= exponent_2 - product_shift;
		exponent_4 <= exponent_gt_prodshift ? exponent_3 : exponent;
		exponent_et_zero <= exponent_4 == 0;
		mul_a <= { a_is_norm, mantissa_a };
		mul_b <= { b_is_norm, mantissa_b };
		product_a <= mul_a[23:0] * mul_b[16:0];
		product_b <= mul_a[23:0] * mul_b[33:17];
		product_c <= mul_a[23:0] * mul_b[50:34];
		product_d <= mul_a[23:0] * mul_b[52:51];
		product_e <= mul_a[40:24] * mul_b[16:0];
		product_f <= mul_a[40:24] * mul_b[33:17];
		product_g <= mul_a[40:24] * mul_b[52:34];
		product_h <= mul_a[52:41] * mul_b[16:0];
		product_i <= mul_a[52:41] * mul_b[33:17];
		product_j <= mul_a[52:41] * mul_b[52:34];
		sum_0 <= product_a[40:17] + product_b;
		sum_1 <= sum_0[41:7] + product_e;
		sum_2 <= sum_1[35:10] + product_c;
		sum_3 <= sum_2[41:7] + product_h;
		sum_4 <= sum_3 + product_f;
		sum_5 <= sum_4[36:10] + product_d;
		sum_6 <= sum_5[27:7] + product_i;
		sum_7 <= sum_6 + product_g;
		sum_8 <= sum_7[36:17] + product_j;
		product <= { sum_8, sum_7[16:0], sum_5[6:0], sum_4[9:0], sum_2[6:0],
					sum_1[9:0], sum_0[6:0], product_a[16:0] };
		product_1 <= product >> exponent_under;
		product_2 <= exponent_gt_expoffset ? product : product_1; 
		product_3 <= product_2 << product_shift_2;
		product_4 <= product_2 << exponent_2;
		product_5 <= exponent_gt_prodshift ? product_3  : product_4;
		product_6 <= exponent_et_zero ? product_5 >> 1 : product_5;
		product_lsb <= |product_6[51:0];
		exponent_5 <= in_zero ? 12'b0 : exponent_4;
		product_shift_2 <= product_shift; // redundant register
			// reduces fanout on product_shift
                shift_inexact <= product_lsb || (exponent_gt_expoffset ? 0 : | (product & ((1<<exponent_under)-1)));
	end // if (enable)
        else shift_inexact <= 0;
end

always @(product)
   casez(product)	
    106'b1?????????????????????????????????????????????????????????????????????????????????????????????????????????: product_shift =  0;
    106'b01????????????????????????????????????????????????????????????????????????????????????????????????????????: product_shift =  1;
    106'b001???????????????????????????????????????????????????????????????????????????????????????????????????????: product_shift =  2;
    106'b0001??????????????????????????????????????????????????????????????????????????????????????????????????????: product_shift =  3;
    106'b00001?????????????????????????????????????????????????????????????????????????????????????????????????????: product_shift =  4;
    106'b000001????????????????????????????????????????????????????????????????????????????????????????????????????: product_shift =  5;
    106'b0000001???????????????????????????????????????????????????????????????????????????????????????????????????: product_shift =  6;
    106'b00000001??????????????????????????????????????????????????????????????????????????????????????????????????: product_shift =  7;
    106'b000000001?????????????????????????????????????????????????????????????????????????????????????????????????: product_shift =  8;
    106'b0000000001????????????????????????????????????????????????????????????????????????????????????????????????: product_shift =  9;
    106'b00000000001???????????????????????????????????????????????????????????????????????????????????????????????: product_shift =  10;
    106'b000000000001??????????????????????????????????????????????????????????????????????????????????????????????: product_shift =  11;
    106'b0000000000001?????????????????????????????????????????????????????????????????????????????????????????????: product_shift =  12;
    106'b00000000000001????????????????????????????????????????????????????????????????????????????????????????????: product_shift =  13;
    106'b000000000000001???????????????????????????????????????????????????????????????????????????????????????????: product_shift =  14;
    106'b0000000000000001??????????????????????????????????????????????????????????????????????????????????????????: product_shift =  15;
    106'b00000000000000001?????????????????????????????????????????????????????????????????????????????????????????: product_shift =  16;
    106'b000000000000000001????????????????????????????????????????????????????????????????????????????????????????: product_shift =  17;
    106'b0000000000000000001???????????????????????????????????????????????????????????????????????????????????????: product_shift =  18;
    106'b00000000000000000001??????????????????????????????????????????????????????????????????????????????????????: product_shift =  19;
    106'b000000000000000000001?????????????????????????????????????????????????????????????????????????????????????: product_shift =  20;
    106'b0000000000000000000001????????????????????????????????????????????????????????????????????????????????????: product_shift =  21;
    106'b00000000000000000000001???????????????????????????????????????????????????????????????????????????????????: product_shift =  22;
    106'b000000000000000000000001??????????????????????????????????????????????????????????????????????????????????: product_shift =  23;
    106'b0000000000000000000000001?????????????????????????????????????????????????????????????????????????????????: product_shift =  24;
    106'b00000000000000000000000001????????????????????????????????????????????????????????????????????????????????: product_shift =  25;
    106'b000000000000000000000000001???????????????????????????????????????????????????????????????????????????????: product_shift =  26;
    106'b0000000000000000000000000001??????????????????????????????????????????????????????????????????????????????: product_shift =  27;
    106'b00000000000000000000000000001?????????????????????????????????????????????????????????????????????????????: product_shift =  28;
    106'b000000000000000000000000000001????????????????????????????????????????????????????????????????????????????: product_shift =  29;
    106'b0000000000000000000000000000001???????????????????????????????????????????????????????????????????????????: product_shift =  30;
    106'b00000000000000000000000000000001??????????????????????????????????????????????????????????????????????????: product_shift =  31;
    106'b000000000000000000000000000000001?????????????????????????????????????????????????????????????????????????: product_shift =  32;
    106'b0000000000000000000000000000000001????????????????????????????????????????????????????????????????????????: product_shift =  33;
    106'b00000000000000000000000000000000001???????????????????????????????????????????????????????????????????????: product_shift =  34;
    106'b000000000000000000000000000000000001??????????????????????????????????????????????????????????????????????: product_shift =  35;
    106'b0000000000000000000000000000000000001?????????????????????????????????????????????????????????????????????: product_shift =  36;
    106'b00000000000000000000000000000000000001????????????????????????????????????????????????????????????????????: product_shift =  37;
    106'b000000000000000000000000000000000000001???????????????????????????????????????????????????????????????????: product_shift =  38;
    106'b0000000000000000000000000000000000000001??????????????????????????????????????????????????????????????????: product_shift =  39;
    106'b00000000000000000000000000000000000000001?????????????????????????????????????????????????????????????????: product_shift =  40;
    106'b000000000000000000000000000000000000000001????????????????????????????????????????????????????????????????: product_shift =  41;
    106'b0000000000000000000000000000000000000000001???????????????????????????????????????????????????????????????: product_shift =  42;
    106'b00000000000000000000000000000000000000000001??????????????????????????????????????????????????????????????: product_shift =  43;
    106'b000000000000000000000000000000000000000000001?????????????????????????????????????????????????????????????: product_shift =  44;
    106'b0000000000000000000000000000000000000000000001????????????????????????????????????????????????????????????: product_shift =  45;
    106'b00000000000000000000000000000000000000000000001???????????????????????????????????????????????????????????: product_shift =  46;
    106'b000000000000000000000000000000000000000000000001??????????????????????????????????????????????????????????: product_shift =  47;
    106'b0000000000000000000000000000000000000000000000001?????????????????????????????????????????????????????????: product_shift =  48;
    106'b00000000000000000000000000000000000000000000000001????????????????????????????????????????????????????????: product_shift =  49;
    106'b000000000000000000000000000000000000000000000000001???????????????????????????????????????????????????????: product_shift =  50;
    106'b0000000000000000000000000000000000000000000000000001??????????????????????????????????????????????????????: product_shift =  51;
    106'b00000000000000000000000000000000000000000000000000001?????????????????????????????????????????????????????: product_shift =  52;
    106'b000000000000000000000000000000000000000000000000000000????????????????????????????????????????????????????: product_shift =  53;
    // It's not necessary to go past 53, because you will only get more than 53 zeros
    // when multiplying 2 denormalized numbers together, in which case you will underflow
    endcase	

endmodule
