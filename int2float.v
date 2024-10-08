module int_to_float(output [31:0] flt_value,  input [31:0] int_value);

    integer i;
    reg [7:0] exp;
    reg [22:0] mantissa;

    assign flt_value = {int_value[31], exp, mantissa};

    always @* begin
        exp = 0;
        mantissa = 0;

        if(int_value != 32'b0) begin
            for(i = 0; i < 32; i = i + 1)
                if(int_value[i]) exp = i;

            if(exp > 23)
                mantissa = int_value >> (exp - 23);
            else if(exp < 23)
                mantissa = int_value << (23 - exp);
            else
                mantissa = int_value;

            exp = exp + 127;
        end
    end
endmodule