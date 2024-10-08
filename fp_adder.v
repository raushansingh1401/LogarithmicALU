`timescale 1ns / 1ps
module fp_adder(a,b,clk,out);
input[31:0]a,b;
input clk;
output [31:0]out;
wire [7:0]e1,e2,ex,ey,exy,ex1,ey1,ex2,ex3;
wire s1,s2,s,s3,sr,sn,s4,sx1,sy1,sn1,sn2,sn3,sn4,sr1,sr2,sn5,sn6;
wire [23:0]m1,m2,mx,my,mxy,mx1,my1;
wire [24:0]mxy1,mxy2;
assign s1=a[31];
assign s2=b[31];
assign e1=a[30:23];
assign e2=b[30:23];
assign m1[23]=1'b1;
assign m2[23]=1'b1;
assign m1[22:0]=a[22:0];
assign m2[22:0]=b[22:0];
//submodule for compare and shfit
cmpshift as(e1[7:0],e2[7:0],s1,s2,m1[23:0],m2[23:0],clk,ex,ey,mx,my,s,sx1,sy1);
buffer1 buff1(ex,ey,sx1,sy1,mx,my,s,clk,ex1,ey1,mx1,my1,sn,sn1,sn2);
//sub module for mantissa addition snd subtraction
faddsub as1(mx1,my1,sn1,sn2,sn,ex1,clk,mxy1,ex2,sn3,sn4,s3,sr1);
buffer2 buff2(mxy1,s3,sr1,ex2,sn3,sn4,clk,mxy2,ex3,sn5,sn6,s4,sr2);
//sub module for normalization
normalized as2(mxy2,sr2,sn5,sn6,s4,clk,ex3,sr,exy,mxy);
assign out={sr,exy,mxy[22:0]};
endmodule

module buffer2(mxy1,s3,sr1,ex,sn3,sn4,clk,mxy2,ex3,sn5,sn6,s4,sr2);
input [24:0]mxy1;
input s3,clk,sr1,sn3,sn4;
input [7:0]ex;
output reg[24:0]mxy2;
output reg[7:0]ex3;
output reg s4,sn5,sn6,sr2;
always@(posedge clk)
begin
sr2=sr1;
sn5=sn3;
sn6=sn4;
ex3=ex;
mxy2=mxy1;
s4=s3;
end
endmodule
module buffer1(ex,ey,sx1,sy1,mx,my,s,clk,ex1,ey1,mx1,my1,sn,sn1,sn2);
input [7:0]ex,ey;
input [23:0]mx,my;
input s,clk,sx1,sy1;
output reg [7:0]ex1,ey1;
output reg [23:0]mx1,my1;
output reg sn,sn1,sn2;
always@(posedge clk)
begin
sn1=sx1;
sn2=sy1;
ex1=ex;
ey1=ey;
mx1=mx;
my1=my;
sn=s;
end
endmodule

module normalized(mxy1,s,s1,s2,s3,clk,ex,sr,exy,mxy);
input[24:0]mxy1;
input s,s1,s2,s3,clk;
input[7:0]ex;
output reg sr;
output reg[7:0]exy;
output reg[23:0]mxy;
reg [24:0]mxy2;
always@(posedge clk)
begin
sr=s?s1^(mxy1[24]&s3):s2^(mxy1[24]&s3);
mxy2=(mxy1[24]&s3)?~mxy1+25'b1:mxy1;
mxy=mxy2[24:1];
exy=ex;
repeat(24)
begin
if(mxy[23]==1'b0)
begin
mxy=mxy<<1'b1;
exy=exy-8'b1;
end
end
end
endmodule

module faddsub(a,b,s1,s2,sn,ex1,clk,out,ex2,sn3,sn4,s,sr1); //submodule for addition or subtraction
input [23:0]a,b;
input[7:0]ex1;
input s1,s2,clk,sn;
output reg [23:0]ex2;
output reg[24:0]out;
output reg s,sn3,sn4,sr1;
always@(posedge clk)
begin
ex2=ex1;
sr1=sn;
sn3=s1;
sn4=s2;
s=s1^s2;
if(s)
begin
out=a-b;
end
else
begin
out=a+b;
end
end
endmodule
module cmpshift(e1,e2,s1,s2,m1,m2,clk,ex,ey,mx,my,s,sx1,sy1); //module for copare &shift
input [7:0]e1,e2;
input [23:0]m1,m2;
input clk,s1,s2;
output reg[7:0]ex,ey;
output reg[23:0]mx,my;
output reg s,sx1,sy1;
reg [7:0]diff;
always@(posedge clk)
begin
sx1=s1;
sy1=s2;
if(e1==e2)
begin
ex=e1+8'b1;
ey=e2+8'b1;
mx=m1;
my=m2;
s=1'b1;
end
else if(e1>e2)
begin
diff=e1-e2;
ex=e1+8'b1;
ey=e1+8'b1;
mx=m1;
my=m2>>diff;
s=1'b1;
end
else
begin
diff=e2-e1;
ex=e2+8'b1;
ey=e2+8'b1;
mx=m2;
my=m1>>diff;
s=1'b0;
end
end
endmodule
/*`define L 32
`define exp 8
`define upper_exp 254
`define lower_exp 1
`define bias 127
module fp_adder( input [`L-1:0]  fp_input1,
                input [`L-1:0]  	fp_input2,
                input 			 	mode, 
                input			   clock,
                input 		 	 	enable,
					 input 				rst,
                output [`L-1:0] 	fp_output,
                output 		    	fp_exception
    );

reg sign_input1;
reg sign_input2;
reg sign_output;
reg sign_output_fw_1;
reg sign_output_fw_2;
reg sign_output_fw_3;
reg out_zero_in_zero;
reg out_zero_shift_zero;
reg out_zero_in_zero_fw_1;
reg out_zero_shift_zero_fw_1;
reg out_zero_in_zero_fw_2;
reg out_zero_shift_zero_fw_2;
reg out_zero_in_zero_fw_3;
reg zero_in_zero_reg;
reg zero_shift_zero_reg;
reg zero_in_zero_reg_fw_1;
reg zero_shift_zero_reg_fw_1;
reg zero_in_zero_reg_fw_2;
reg zero_shift_zero_reg_fw_2;
reg zero_in_zero_reg_fw_3;
reg exp_eq;
reg overflow;
reg norm_check;
reg norm_check_fw;
reg overflow_fw;
reg [`L-1:0] output_sum;
reg [`L-`exp-1:0] in1,in2;
reg [`L-`exp-1:0] result_sum_man;
reg [`L-`exp-1:0] result_sum_man_fw;
reg [`exp-1:0] res_exp_eq;
reg [`exp-1:0] res_exp_eq_fw;
reg [`exp-1:0] res_exp_add;
reg [4:0]  count;
reg add_done;
reg norm_start;
reg norm_done;
reg overflow_exception_1;
reg overflow_exception_1_fw;
reg underflow_exception_1;
reg out_nan;
reg out_nan_fw_1;
reg out_nan_fw_2;
reg out_nan_fw_3;
reg out_inf;
reg out_inf_fw_1;
reg out_inf_fw_2;
reg out_inf_fw_3;
wire overflow_exception;
wire underflow_exception;


always @(posedge clock)
begin
if(rst) begin
  out_zero_in_zero  	<= 0;
  sign_input1				<= 0;
  sign_input2 			<= 0;
  sign_output				<= 0;
  zero_in_zero_reg		<= 0;
  in1 					   <= 0; 
  in2 				      <= 0;
  exp_eq 					<= 0;
  res_exp_eq				<= 0;
  out_nan				   <= 0;
  out_inf				   <= 0;
 end
else begin 
  if(enable)
  begin
    sign_input1		<= fp_input1[`L-1];
    if(mode)
      sign_input2 <= !fp_input2[`L-1];
    else
      sign_input2 <= fp_input2[`L-1];
      
    if(fp_input2[`L-1:0] == 32'h7f800000 && fp_input1[`L-1:0] == 32'h7f800000)
    begin
      out_nan <= 1;
    end
    else if(fp_input2[`L-1:0] == 32'h7f800000 || fp_input1[`L-1:0] == 32'h7f800000)
    begin
      out_inf <= 1;
    end
    else if(fp_input1[`L-1:0] == 32'b0)
    begin
      zero_in_zero_reg		<= 0;  //Checking if input 1 is 0
      out_zero_in_zero   	<= 1;
    end	
    else if (fp_input2[`L-1:0] == 32'b0)
    begin
      zero_in_zero_reg		<= 1;  //Checking if input 2 is 0
      out_zero_in_zero   	<= 1;
    end 	
    else
    begin
      exp_eq									<= 1;
      if(fp_input1[`L-2:0] > fp_input2[`L-2:0])
      begin
        sign_output							<= fp_input1[`L-1];
        res_exp_eq					   	<= fp_input1[`L-2:`L-`exp-1];
        in1 									<= {1'b1,  fp_input1[`L-`exp-2:0]};
        in2				 						<= ({1'b1, fp_input2[`L-`exp-2:0]} >> (fp_input1[`L-2:`L-`exp-1]-fp_input2[`L-2:`L-`exp-1]));  //1 is the hidden bit
        end
      else
      begin
        sign_output							<= mode ^ fp_input2[`L-1];
        res_exp_eq					   	<= fp_input2[`L-2:`L-`exp-1];
        in1              					<= ({1'b1, fp_input1[`L-`exp-2:0]} >> (fp_input2[`L-2:`L-`exp-1]-fp_input1[`L-2:`L-`exp-1]));
        in2 									<= {1'b1,  fp_input2[`L-`exp-2:0]};
      end			
    end
  end
end
end
always @(posedge clock)
begin	
	if(rst) begin
		out_zero_shift_zero 	 <= 0;
		zero_shift_zero_reg	 <= 0;
		overflow 			    <= 0;
		norm_check 				 <= 0;
		result_sum_man 		 <= 0;
		norm_start 				 <= 0;	
		res_exp_eq_fw			 <= 0;
		sign_output_fw_1		 <= 0;
		zero_in_zero_reg_fw_1 <= 0;
		out_zero_in_zero_fw_1 <= 0;
		out_nan_fw_1			 <= 0;
		out_inf_fw_1			 <= 0;
	end
	else begin  
		sign_output_fw_1		 <= sign_output;
		zero_in_zero_reg_fw_1 <= zero_in_zero_reg;
		out_zero_in_zero_fw_1 <= out_zero_in_zero;
		out_nan_fw_1			 <= out_nan;
		out_inf_fw_1			 <= out_inf;
	end
	if (exp_eq)
		begin	
			res_exp_eq_fw		<= res_exp_eq;
			if (in2[`L-`exp-2:0] == 23'b0) 
				begin
					zero_shift_zero_reg	 <= 1;  //Checking if input 2 became 0
					out_zero_shift_zero   <= 1;
				end
			else if (in1[`L-`exp-2:0] == 23'b0)
				begin
					zero_shift_zero_reg	 <= 0;   //Checking if input 1 became 0
					out_zero_shift_zero   <= 1;
				end
			else
				begin
					norm_start <= 1;
					if(sign_input1 ^ sign_input2)
						begin		
							norm_check <= 1;
							if(sign_output == sign_input1)
								begin
									result_sum_man <= in1 - in2;
								end
							else
								begin
									result_sum_man <= in2 - in1;
								end
						end
					else
						begin				
							{overflow,result_sum_man}  <= in1 + in2;
						end
				end
	end
end
always @(posedge clock)
begin
if(rst) begin
  count 		   				<= 0;
  res_exp_add						<= 0;
  norm_done						<= 0;
  result_sum_man_fw				<= 0;
  norm_check_fw					<= 0;
  overflow_fw						<= 0;
  sign_output_fw_2				<= 0;
  zero_in_zero_reg_fw_2 		<= 0;
  out_zero_in_zero_fw_2 		<= 0;
  zero_shift_zero_reg_fw_1   <=  0;
  out_zero_shift_zero_fw_1	<= 0;
  overflow_exception_1 	   <= 0;
  out_nan_fw_2			 		<= 0;
  out_inf_fw_2			 		<= 0;
 end
else begin

  sign_output_fw_2			<= sign_output_fw_1;
  zero_in_zero_reg_fw_2 	<= zero_in_zero_reg_fw_1;
  out_zero_in_zero_fw_2 	<= out_zero_in_zero_fw_1;
  zero_shift_zero_reg_fw_1 <= zero_shift_zero_reg;
  out_zero_shift_zero_fw_1	<= out_zero_shift_zero;
  overflow_exception_1 	   <= 0;
  out_nan_fw_2			 		<= out_nan_fw_1;
  out_inf_fw_2			 		<= out_inf_fw_1;
  if(norm_start)
  begin
    norm_check_fw		  		<= norm_check;
    result_sum_man_fw   	<= result_sum_man;
    overflow_fw			  	<= overflow;
    if(overflow)
    begin
        res_exp_add   		<= res_exp_eq_fw + 1;
        if ( (res_exp_eq_fw + 1'b1) > `upper_exp)
          overflow_exception_1 <= 1;
        norm_done	  <= 1;
    end
    else
    begin
        res_exp_add	  <= res_exp_eq_fw;
        norm_done	  <= 1;
    end
          
    if(norm_check)
    begin
      if (result_sum_man[`L-`exp-1]==1'b1)  //Need to shift till we obtain a 1 as hidden bit
        count <= 0;
      else if (result_sum_man[`L-`exp-2]==1'b1)
        count <= 1;
      else if (result_sum_man[`L-`exp-3]==1'b1)
        count <= 2;
      else if (result_sum_man[`L-`exp-4]==1'b1)
        count <= 3;
      else if (result_sum_man[`L-`exp-5]==1'b1)
        count <= 4;
      else if (result_sum_man[`L-`exp-6]==1'b1)
        count <= 5;
      else if (result_sum_man[`L-`exp-7]==1'b1)
        count <= 6;
      else if (result_sum_man[`L-`exp-8]==1'b1)
        count <= 7;
      else if (result_sum_man[`L-`exp-9]==1'b1)
        count <= 8;
      else if (result_sum_man[`L-`exp-10]==1'b1)
        count <= 9;
      else if (result_sum_man[`L-`exp-11]==1'b1)
        count <= 10;
      else if (result_sum_man[`L-`exp-12]==1'b1)
        count <= 11;
      else if (result_sum_man[`L-`exp-13]==1'b1)
        count <= 12;
      else if (result_sum_man[`L-`exp-14]==1'b1)
        count <= 13;
      else if (result_sum_man[`L-`exp-15]==1'b1)
        count <= 14;
      else if (result_sum_man[`L-`exp-16]==1'b1)
        count <= 15;
      else if (result_sum_man[`L-`exp-17]==1'b1)
        count <= 16;
      else if (result_sum_man[`L-`exp-18]==1'b1)
        count <= 17;
      else if (result_sum_man[`L-`exp-19]==1'b1)
        count <= 18;
      else if (result_sum_man[`L-`exp-20]==1'b1)
        count <= 19;
      else if (result_sum_man[`L-`exp-21]==1'b1)
        count <= 20;
      else if (result_sum_man[`L-`exp-22]==1'b1)
        count <= 21;
      else if (result_sum_man[`L-`exp-23]==1'b1)
        count <= 22;
      else
        count <= 23;	
    end
  end
end
end
always @(posedge clock)
begin
if(rst) begin
  add_done 				 			<= 0;
  output_sum				 		<= 0;
  zero_in_zero_reg_fw_3 		<= 0;
  out_zero_in_zero_fw_3 		<=0;
  zero_shift_zero_reg_fw_2   	<=0;
  out_zero_shift_zero_fw_2		<= 0;
  overflow_exception_1_fw	   <= 0;
  underflow_exception_1			<= 0;
  out_nan_fw_3			 			<= 0;
  out_inf_fw_3			 			<= 0;
  sign_output_fw_3				<= 0;
  end
  else begin
  zero_in_zero_reg_fw_3 		<= zero_in_zero_reg_fw_2;
  out_zero_in_zero_fw_3 		<= out_zero_in_zero_fw_2;
  zero_shift_zero_reg_fw_2   	<= zero_shift_zero_reg_fw_1;
  out_zero_shift_zero_fw_2		<= out_zero_shift_zero_fw_1;
  overflow_exception_1_fw	   <= overflow_exception_1;
  out_nan_fw_3			 			<= out_nan_fw_2;
  out_inf_fw_3			 			<= out_inf_fw_2;
  sign_output_fw_3				<= sign_output_fw_2;
  if(norm_done)
  begin
    output_sum[`L-1] 			<= sign_output_fw_2;
    if(norm_check_fw)
    begin	
      output_sum[`L-`exp-2:0]      		<= result_sum_man_fw[`L-`exp-2:0]<<(count);	
      output_sum[`L-2:`L-`exp-1]   		<= res_exp_add -(count);			
      add_done 								<= 1;
      if ( (res_exp_add -(count)) < `lower_exp)
        underflow_exception_1 			<= 1;
    end
    else
    begin
      output_sum[`L-`exp-2:0]      	<= overflow_fw ? result_sum_man_fw[`L-`exp-1:1] : result_sum_man_fw[`L-`exp-2:0];
      output_sum[`L-2:`L-`exp-1]  	<= res_exp_add;
      add_done 							<= 1;
    end
  end
end
end
//if(rst==1'b0)
//begin
assign fp_output = add_done ? output_sum : (out_zero_in_zero_fw_3 ? (zero_in_zero_reg_fw_3 ? fp_input1 : fp_input2) : out_zero_shift_zero_fw_2 ? (zero_shift_zero_reg_fw_2 ? fp_input1 : fp_input2) : overflow_exception ? {sign_output_fw_3,31'h7f800000} : underflow_exception ? {sign_output_fw_3,31'h00000000} : out_nan_fw_3 ? {sign_output_fw_3,31'h7f800001} : 31'bz);
assign overflow_exception  = overflow_exception_1_fw  || out_inf_fw_3;
assign underflow_exception = underflow_exception_1;
assign fp_exception        = overflow_exception || underflow_exception;
//end
endmodule*/