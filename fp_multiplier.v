`timescale 1ns / 1ps
`define nodes 8
`define nodes_8
`define DATA_WIDTH 32
`define ADDR_WIDTH 32
`define FLIT_WIDTH 18
`define num_device_bits $clog2(`nodes)
`define vc_num 4 
`define vc_channel_bits $clog2(`vc_num)  
`define device_ID 2
`define ADDR_LEN 4
`define dest_add_bits 3
`define vc_enable
`define DATA_WIDTH_ML 16
`define ADDR_EXT_RAM 8
`define WID_EXT_RAM `DATA_WIDTH_ML
`define DATA_EXT_RAM 8
`define ADDR_RAM 12
`define WID_RAM `DATA_WIDTH_ML
`define REG_BANK_SIZE 64
`define CONTR_STATES 14
`define CONTR_STATES_BITS 6
`define N_PE 32
`define WID_PE_BITS `DATA_WIDTH_ML
`define N_CONV 32
`define BUS_PE_BITS `N_CONV*`WID_PE_BITS
`define WID_CONV_OUT `DATA_WIDTH_ML
`define WID_LINE `DATA_WIDTH_ML
`define WID_FIFO `DATA_WIDTH_ML
`define ADDR_FIFO 9
`define DEP_FIFO 2**`ADDR_FIFO
`define	WID_FILTER	`DATA_WIDTH_ML
`define	WID_MAC_MULT	32 //`WID_FIFO+`WID_LINE
`define	WID_MAC_OUT		36 //`WID_MAC_MU
`define ADDR_LEN_NOC  3
`define DATA_WIDTH_NOC  32
`define L 32
`define exp 8
`define bias 7'd127
`define upper_exp 254
`define lower_exp 1
`define   ADDR_LEN_NOC  3
`define   DATA_WIDTH_NOC 32
`define ADDR_EXT_RAM 8
`define N 	  32   
`define LWC   (2*`N) 
`define BC    512   
`define SBC   4    
`define LC    (`BC*`SBC)  
`define CI    32    	
`define LI 	  (`LC*`CI)   
`define	WSB	  2    
`define WBC   (`SBC*`WSB)  
`define sLC	  9     
`define sLI   14	
`define sWBC  3 	
`define sCI   5 
`define nodes 8
`define DATA_WIDTH 32
`define ADDR_WIDTH 32
`define FLIT_WIDTH 18// 8 bits for fpga
`define num_device_bits $clog2(`nodes)
`define vc_num 4 
`define vc_channel_bits $clog2(`vc_num)  
`define device_ID 2//different ID's for different nodes	
`define ADDR_LEN 4
`define dest_add_bits 3
`define vc_enable 
module fp_multiplier(input [`L-1:0]  fp_input1,
            input [`L-1:0]  fp_input2,
            input 			 clock,
            input 	  		 enable,
            //input [`L-1:0]  instr_timeE,
            output [`L-1:0] fp_output,
			
            output 		    fp_exception
    );

wire [2*`L+-2*`exp-1:0]result_man;
main_multiplier_fpu_test m1(.a({1'b1,fp_input1[`L-2-`exp:0]}),.b({1'b1,fp_input2[`L-2-`exp:0]}),.clk(clock),.c_reg(result_man));

wire overflow_exception;
wire underflow_exception;

reg [`exp-1:0]result_exp;
reg [`exp-1:0]out_exp;
reg [`L-`exp-2:0] out_man;
reg [`L-2:0] out_res;
reg out_inf;
reg out_zero;
reg out_nan;
reg out_inf_fw_1;
reg out_zero_fw_1;
reg out_nan_fw_1;
reg out_inf_fw_2;
reg out_zero_fw_2;
reg out_nan_fw_2;
reg do_norm;
reg overflow_exception_1;
reg underflow_exception_1;
reg overflow_exception_1_fw;
reg underflow_exception_1_fw;
reg overflow_exception_2;
reg norm_done;
reg exp_adj_done;
reg output_sign;
reg output_sign_fw_1;
reg output_sign_fw_2;

always @(posedge clock)
begin	
  if (enable)
  begin
    output_sign <= fp_input1[`L-1] ^ fp_input2[`L-1];  //Sign bit
    if (fp_input1[`L-2:0] == 31'h7f800000 && fp_input2[`L-2:0] == 31'b0)
    begin
      out_nan  <= 1;  //Checking if input 1 is inf and input 2 is zero
      out_zero <= 0; 
      out_inf  <= 0; 
      do_norm	<= 0;
    end	
    else if(fp_input2[`L-2:0] == 31'h7f800000 && fp_input1[`L-2:0] == 31'b0)
    begin
      out_nan  <= 1;  //Checking if input 2 is inf and input 1 is zero
      out_zero <= 0; 
      out_inf  <= 0; 
      do_norm	<= 0;
    end
    else if(fp_input1[`L-2:0] == 31'h7f800000 || fp_input2[`L-2:0] == 31'h7f800000)
    begin
      out_inf  <= 1;  //Checking if input 1 or input 2 is inf
      out_zero <= 0;
      out_nan  <= 0;
      do_norm	<= 0;
    end			
    else if(fp_input1[`L-2:0] == 31'b0 || fp_input2[`L-2:0] == 31'b0)
    begin
      out_zero <= 1;  //Checking if input 1 or input 2 is zero
      out_inf  <= 0;  
      out_nan  <= 0;
      do_norm	<= 0;
    end	
    else
    begin		
      out_inf  	<= 0;  
      out_zero 	<= 0;
      out_nan		<= 0;
      do_norm		<= 1;
      result_exp  <= fp_input1[`L-2:`L-1-`exp] + fp_input2[`L-2:`L-1-`exp] - `bias;						
    end
  end
  else
  begin
    out_zero      <= out_zero;
    out_nan		  <= out_nan;
    out_inf		  <= out_inf;
    result_exp	  <= result_exp;
    output_sign	  <= output_sign;		
    do_norm 		  <= do_norm;
    
  end
end

always @(posedge clock)
begin
  norm_done  	  			 <= 0;
  out_man	     			 <= 0;
  overflow_exception_1  <= 0;
  underflow_exception_1 <= 0;
  out_zero_fw_1 			 <= out_zero;
  out_nan_fw_1  			 <= out_nan;
  out_inf_fw_1  			 <= out_inf;
  output_sign_fw_1		 <= output_sign;
  
  if(do_norm)
  begin
    if (result_exp > `upper_exp)
    begin
      overflow_exception_1 	<= 1;  //Checking for exponent overflow and underflow
      underflow_exception_1 	<= 0;
    end
    else if (result_exp < `lower_exp)
    begin
      underflow_exception_1 	<= 1;
      overflow_exception_1 	<= 0;
    end
    else
    begin
      if(result_man[2*`L+-2*`exp-1])
      begin
        out_exp <= result_exp + 1'b1; //Adj the exponent
        out_man <= result_man [2*`L+-2*`exp-2 : 2*`L+-2*`exp-2 -(`L-`exp-2)]; //Normalizing the result
        norm_done  <= 1;
      end
      else if (result_man[2*`L+-2*`exp-2])
      begin
        out_exp <= result_exp; //Adj the exponent	
        out_man <= result_man [2*`L+-2*`exp-3 : 2*`L+-2*`exp-3 -(`L-`exp-2)];
        norm_done  <= 1;
      end		
      else
        out_man <= 23'b0;
    end
  end
end

always @(posedge clock)
begin
  exp_adj_done 				 <= 0;
  overflow_exception_2 	 <= 0;
  out_res						 <= 0;
  overflow_exception_1_fw  <= overflow_exception_1;
  underflow_exception_1_fw <= underflow_exception_1;
  out_zero_fw_2 			 	 <= out_zero_fw_1;
  out_nan_fw_2  			 	 <= out_nan_fw_1;
  out_inf_fw_2  			 	 <= out_inf_fw_1;
  output_sign_fw_2		 	 <= output_sign_fw_1;
  if(norm_done)
  begin		
    if (out_exp > `upper_exp)
      overflow_exception_2 <= 1;
    else
    begin
      exp_adj_done <= 1;
      out_res      <= {out_exp,out_man};
    end
  end
end

assign fp_output[`L-1]     = output_sign_fw_2;
assign fp_output[`L-2:0]   = exp_adj_done ? out_res : underflow_exception ? 31'b0: overflow_exception ? 31'h7f800000 : out_nan_fw_2 ? 31'h7f800001 : 31'bz;
assign overflow_exception  = overflow_exception_1_fw || overflow_exception_2 || out_inf_fw_2;
assign underflow_exception = underflow_exception_1_fw || out_zero_fw_2;
assign fp_exception        = overflow_exception || underflow_exception;


endmodule


module main_multiplier_fpu_test(
 input [23:0]	a,
 input [23:0] 	b,
 input 			clk,
 input 			en,
 output reg [47:0] 	c_reg
    );
   
   
  reg [23:0]  a_reg;
  reg [23:0]  b_reg;
  
  wire [47:0] c ; 
  
  always @(posedge clk) begin
    a_reg <= a ; 
    b_reg <= b ; 
    c_reg <= c ; 
    end 
  
  multiplier_fpu_test mul(
            .a(a_reg), 
            .b(b_reg), 
            .c(c),
            .clk(clk)
            );
             
endmodule

module multiplier_fpu_test(
 input [23:0] 	a,
 input [23:0]	b,
 input 			clk,
 output reg [47:0] 	c
    );
   wire [47:0]	c0;
   wire [47:0]	c1;
   wire [47:0]	c2;
   wire [47:0]	c3;
   wire [47:0]	c4;
   wire [47:0]	c5;
   wire [47:0]	c6;
   wire [47:0]	c7;
   wire [47:0]	c8;
   wire [47:0]	c9;
   wire [47:0]	c10;
   wire [47:0]	c11;
   wire [47:0]	c12;
   reg [47:0]	d0;
   reg [47:0]	d1;
   reg [47:0]	d2;
   reg [47:0]	d3;
   reg [47:0]	d4;
   reg [47:0]	d5;
   reg [47:0]	d6;
   reg [47:0]	d7;
   reg [47:0]	d8;
   reg [47:0]	d9;
   reg [47:0]	d10;
   reg [47:0]	d11;
   reg [47:0]	d12;
      
   mini_multiplier_fpu_test mmul0(
                .a(a),
                .b({b[1:0],1'b0}),
                .c(c0)
                );
   mini_multiplier_fpu_test mmul1(
                .a(a),
                .b(b[3:1]),
                .c(c1)
                );
   mini_multiplier_fpu_test mmul2(
                .a(a),
                .b(b[5:3]),
                .c(c2)
                );							
   mini_multiplier_fpu_test mmul3(
                .a(a),
                .b(b[7:5]),
                .c(c3)
                );
   mini_multiplier_fpu_test mmul4(
                .a(a),
                .b(b[9:7]),
                .c(c4)
                );
   mini_multiplier_fpu_test mmul5(
                .a(a),
                .b(b[11:9]),
                .c(c5)
                );
    mini_multiplier_fpu_test mmul6(
                .a(a),
                .b(b[13:11]),
                .c(c6)
                );
    mini_multiplier_fpu_test mmul7(
                .a(a),
                .b(b[15:13]),
                .c(c7)
                );
    mini_multiplier_fpu_test mmul8(
                .a(a),
                .b(b[17:15]),
                .c(c8)
                );
    mini_multiplier_fpu_test mmul9(
                .a(a),
                .b(b[19:17]),
                .c(c9)
                );
    mini_multiplier_fpu_test mmul10(
                .a(a),
                .b(b[21:19]),
                .c(c10)
                );
    mini_multiplier_fpu_test mmul11(
                .a(a),
                .b(b[23:21]),
                .c(c11)
                );
   mini_multiplier_fpu_test mmul12(
                .a(a),
                .b({2'b0,b[23]}),
                .c(c12)
                );
              
   always @( posedge clk) begin
    d0 <= c0 ;
    d1 <= {c1[45:0],2'b0} ;
    d2 <= {c2[43:0],4'b0} ;
    d3 <= {c3[41:0],6'b0} ;
    d4 <= {c4[39:0],8'b0} ;
    d5 <= {c5[37:0],10'b0} ;
    d6 <= {c6[35:0],12'b0} ;
    d7 <= {c7[33:0],14'b0} ;
    d8 <= {c8[31:0],16'b0} ;
    d9 <= {c9[29:0],18'b0} ;
    d10 <= {c10[27:0],20'b0} ;
    d11 <= {c11[25:0],22'b0} ;	
    d12 <= {c12[23:0],24'b0} ;	
   end
   
   reg [47:0] c_temp1, c_temp2, c_temp3, c_temp4, c_temp5, c_temp6, c_temp7, c_temp9, c_temp10, c_temp11, c_temp12; 
   always @(*) begin
    c_temp1 = d0 + d1 ; 
    c_temp2 = d2 + d3 ; 
    c_temp3 = d4 + d5 ; 
    c_temp4 = d6 + d7 ;
    c_temp5 = d8 + d9 ; 
    c_temp6 = d10 + d11 ; 		
    c_temp9 = c_temp1 + c_temp2 ;
    c_temp10 = c_temp3 + c_temp4 ;
    c_temp11 = c_temp5 + c_temp6 ;		
    c_temp12 = c_temp9 + c_temp10;
    c_temp7 = d12 + c_temp11;
    c = c_temp12 + c_temp7;
   end
endmodule
module mini_multiplier_fpu_test(
  input [23:0]	a,
  input [2:0] 	b,
  output reg [47:0] 		c
    );
  
  always @(*) begin
    case (b)
      3'b000 : c <= 1'b0 ; 
      3'b010 : c <= {{24{1'b0}},a} ; 
      3'b100 : c <= ~{{23{1'b0}},a,1'b0} + 48'b1 ;
      3'b110 : c <= ~{{24{1'b0}},a} + 48'b1 ; 
      3'b001 : c <= {{24{1'b0}},a} ;
      3'b011 : c <= {{23{1'b0}},a,1'b0} ; 
      3'b101 : c <= ~{{24{1'b0}},a} + 48'b1 ;
      3'b111 : c <= 1'b0 ;  			
    endcase
  end 
endmodule
