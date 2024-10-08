`timescale 1ns / 1ps
module fp_logarithm(in_val, clk, ln_output,rst);
input[31:0] in_val;
input clk,rst;
output[31:0] ln_output;
wire[31:0] frac, frac_by_2, add_1,log_mant,exp_ln2, mant_flt, exp_flt;
reg[31:0] frac_pipe1,frac_by_2_pipe1, add_pipe1, log_mant_pipe1, exp_ext, exp_ln2_pipe1,mant_ext,exp_flt_val;
reg[22:0] mant;
reg[7:0] exp,exp_val;
reg s;
int_to_float itf1(.int_value(mant_ext), .flt_value(mant_flt));
int_to_float itf2(.int_value(exp_ext), .flt_value(exp_flt));

fp_multiplier 	fpm1(.fp_input1(mant_flt), 		.fp_input2(32'h34000000),  .clock(clk), .enable(1'b1), .fp_output(frac)		);
fp_multiplier 	fpm2(.fp_input1(frac_pipe1), 		.fp_input2(32'hbf000000),  .clock(clk), .enable(1'b1), .fp_output(frac_by_2));
//fp_adder 		fpa1(.fp_input1(frac_by_2_pipe1),.fp_input2(32'h3f800000),  .clock(clk), .enable(1'b1), .rst(rst), .mode(1'b1), .fp_output(add_1)	);
fp_adder 		fpa1(.a(frac_by_2_pipe1),.b(32'h3f800000),  .clk(clk), .out(add_1)	);
fp_multiplier 	fpm3(.fp_input1(frac_pipe1), 		.fp_input2(add_pipe1),	   .clock(clk), .enable(1'b1), .fp_output(log_mant)	);
fp_multiplier	fpm4(.fp_input1(exp_flt_val),			.fp_input2(32'h3f317218),  .clock(clk), .enable(1'b1),.fp_output(exp_ln2));
//fp_adder			fpa2(.fp_input1(exp_ln2_pipe1),	.fp_input2(log_mant_pipe1),.clock(clk), .enable(1'b1), .rst(rst), .mode(1'b0), .fp_output(ln_output));
fp_adder			fpa2(.a(exp_ln2_pipe1),	.b(log_mant_pipe1),.clk(clk),.out(ln_output));

always@(posedge clk)
begin
mant<=in_val[22:0];
exp <=in_val[30:23] -127;
if(exp[7]==1'b1)
begin
exp_val<=-exp;
s=1'b1;end
else
begin
exp_val<=exp;
s=1'b0;
end
exp_ext[7:0]<= exp_val;
exp_ext[31:8]<={24{exp_val[7]}};
exp_flt_val<={s,exp_flt[30:0]};
mant_ext<={8'h00,mant};
frac_pipe1<=frac;
frac_by_2_pipe1<=frac_by_2;
add_pipe1<=add_1;
log_mant_pipe1<=log_mant;
exp_ln2_pipe1<=exp_ln2;
end
endmodule
