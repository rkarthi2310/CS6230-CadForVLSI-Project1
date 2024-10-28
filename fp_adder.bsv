//*************************************************************************
// CS6230 CAD FOR VLSI PROJECT 1: MULTIPLY-ACCUMULATE (MAC) UNIT 
//
// FILE: fp_adder.bsv
//
// AUTHORS: Karthikeyan R CS23S039
//          Arun Prabakar CS23D012
//
//*************************************************************************

package fp_adder;

import adder::*;

interface Ifc_fpadder;
    method ActionValue#(Bit#(32)) fp_add (Bit#(32) a, Bit#(32) b);
endinterface

function Bit#(5) countLeadingZeros(Bit#(25) value);
    Bit#(5) count = 0;
    Bit#(24) mask = 'h800000; // Start with MSB
    
    if (value[24:0] == 0) return 25;
    else if ((value & 'h1000000) != 0) return 0;
    else if ((value & 'h800000) != 0) return 1;
    else if ((value & 'h400000) != 0) return 2;
    else if ((value & 'h200000) != 0) return 3;
    else if ((value & 'h100000) != 0) return 4;
    else if ((value & 'h080000) != 0) return 5;
    else if ((value & 'h040000) != 0) return 6;
    else if ((value & 'h020000) != 0) return 7;
    else if ((value & 'h010000) != 0) return 8;
    else if ((value & 'h008000) != 0) return 9;
    else if ((value & 'h004000) != 0) return 10;
    else if ((value & 'h002000) != 0) return 11;
    else if ((value & 'h001000) != 0) return 12;
    else if ((value & 'h000800) != 0) return 13;
    else if ((value & 'h000400) != 0) return 14;
    else if ((value & 'h000200) != 0) return 15;
    else if ((value & 'h000100) != 0) return 16;
    else if ((value & 'h000080) != 0) return 17;
    else if ((value & 'h000040) != 0) return 18;
    else if ((value & 'h000020) != 0) return 19;
    else if ((value & 'h000010) != 0) return 20;
    else if ((value & 'h000008) != 0) return 21;
    else if ((value & 'h000004) != 0) return 22;
    else if ((value & 'h000002) != 0) return 23;
    else return 24;
endfunction

//(* synthesize *)
module mkFpAdder (Ifc_fpadder);

    let ifc_adder25_1 <- mkAdder25Bit;
    let ifc_adder25_2 <- mkAdder25Bit;
    let ifc_adder8_1 <- mkAdder8Bit;
    let ifc_adder8_2 <- mkAdder8Bit;
    let ifc_adder8_3 <- mkAdder8Bit;

    method ActionValue#(Bit#(32)) fp_add (Bit#(32) a, Bit#(32) b);

        Bit#(1) output_sign = 0;
        Bit#(1) add_or_sub = 0;
        
        Bit#(32) op1 = 0;
        Bit#(32) op2 = 0;
        
        Bit#(25) mantissa1 = 0;
        Bit#(25) mantissa2 = 0;
        
        Bit#(8) exponent1 = 0;
        Bit#(8) exponent2 = 0;
    
        Bit#(9) intermediate_exponent_diff = 0;
        Bit#(8) exponent_diff = 0;
        Bit#(25) intermediate_mantissa2 = 0;
        Bit#(26) intermediate_add_mantissa = 0;
        Bit#(26) intermediate_sub_mantissa = 0;
        Bit#(24) intermediate_sub_mantissa2 = 0;
        Bit#(5) sub_mantissa_shift = 0;
        Bit#(9) intermediate_add_result_exponent = 0;
        Bit#(9) intermediate_sub_result_exponent = 0;
    
        Bit#(32) add_result = 0;
        Bit#(32) sub_result = 0;
        Bit#(32) output_result = 0;

        // Assign the operand with the greater magnitude to op1.
        if (a[30:0] > b[30:0])
        begin
            op1 = a;
            op2 = b; 
        end
        else
        begin
            op1 = b;
            op2 = a;
        end

        //$display ("op1 = %32b", op1);
        //$display ("op2 = %32b", op2);

        // Output sign is the greater operand's sign.
        output_sign = op1[31];
        //$display ("output_sign = %32b", output_sign);

        // Do we perform addition or subtraction?
        // Addition if same operand signs, subtraction otherwise.
        add_or_sub = op1[31] ^ op2[31];
        //$display ("add_or_sub = %32b", add_or_sub);

        // Extract exponents of the operands.
        exponent1 = op1[30:23];
        exponent2 = op2[30:23];
        //$display ("exp1 = %32b", exponent1);
        //$display ("exp2 = %32b", exponent2);

        // Extract operand mantissa. Account for the implicit bit 
        // by checking if its a normal or a subnormal number.
        mantissa1 = (|exponent1 == 1)?{1'b1, op1[22:0], 1'b0}:{1'b0, op1[22:0], 1'b0};
        mantissa2 = (|exponent2 == 1)?{1'b1, op2[22:0], 1'b0}:{1'b0, op2[22:0], 1'b0};
        //$display ("mantissa1 = %32b", mantissa1);
        //$display ("mantissa2 = %32b", mantissa2);

        // Calculate the difference in exponents.
        //exponent_diff = exponent1 - exponent2;
        intermediate_exponent_diff <- ifc_adder8_1.add(exponent1, exponent2, 1'b1);
        exponent_diff = intermediate_exponent_diff[7:0];
        //$display ("exp_diff = %0d", exponent_diff);

        // Calculate intermediate mantissa obtained after making exponents equal.
        intermediate_mantissa2 = mantissa2 >> exponent_diff;
        //$display ("intermediate_mantissa2 = %32b", intermediate_mantissa2);

        // Addition
        intermediate_add_mantissa <- ifc_adder25_1.add(mantissa1, intermediate_mantissa2, 1'b0);
        //$display ("intermediate_add_mantissa = %32b", intermediate_add_mantissa);
        add_result[22:0] = (intermediate_add_mantissa[25] == 1'b1) ? intermediate_add_mantissa[24:2] : intermediate_add_mantissa[23:1];
        if(intermediate_add_mantissa[25] == 1'b1)
        begin
            intermediate_add_result_exponent <- ifc_adder8_2.add(zeroExtend(1'b1), exponent1, 1'b0);
            add_result[30:23] = intermediate_add_result_exponent[7:0];
        end
        else
        begin
            add_result[30:23] = exponent1;
        end
        add_result[31] = output_sign;

        // Subtraction
        intermediate_sub_mantissa <- ifc_adder25_2.add(mantissa1, intermediate_mantissa2, 1'b1);
        //$display ("intermediate_sub_mantissa = %32b", intermediate_sub_mantissa);
        sub_mantissa_shift = countLeadingZeros(intermediate_sub_mantissa[24:0]);
        //sub_result[22:0] = (intermediate_sub_mantissa[23] == 1'b0) ? ({intermediate_sub_mantissa[21:0], 1'b0}) : intermediate_sub_mantissa[22:0];
        intermediate_sub_mantissa2 = (intermediate_sub_mantissa[23:0] << sub_mantissa_shift); 
        sub_result[22:0] = intermediate_sub_mantissa2[23:1];
        intermediate_sub_result_exponent <- ifc_adder8_3.add(exponent1, zeroExtend(sub_mantissa_shift), 1'b1);
        sub_result[30:23] = intermediate_sub_result_exponent[7:0];
        /*
        if(intermediate_sub_mantissa[23] == 1'b0)
        begin
            intermediate_sub_result_exponent <- ifc_adder8_3.add(exponent1, zeroExtend(sub_mantissa_shift), 1'b1);
            sub_result[30:23] = intermediate_sub_result_exponent[7:0];
        end
        else
        begin
            sub_result[30:23] = exponent1;
        end*/
        sub_result[31] = output_sign;
        
        //$display ("add_result = %32b", add_result);
        //$display ("sub_result = %32b", sub_result);

        // Assign result
        output_result = (add_or_sub == 1'b1) ? sub_result : add_result;
        //$display ("output_result = %32b", output_result);

        return output_result;
        
    endmethod
endmodule

//(* synthesize *)
module mkTb (Empty);
    Ifc_fpadder ifc <- mkFpAdder;

    rule test;
        Bit#(32) ans;
        //ans <- ifc.fp_add(32'b01000011011101100100011100000000, 32'b01000001010100110011100011011101);
        //$display ("The answer is: %0b", ans);
        ans <- ifc.fp_add(32'b00000010000100000000000000000000, 32'b10000001111111111111111111111111);
        $display ("The answer is: %32b", ans);
        $finish (0);
    endrule

endmodule: mkTb

//(* synthesize *)
module mkAdder25Bit ( Ifc_adder#(25));
    let ifc();
    mkAdder _temp(ifc);
    return ifc;
endmodule 

//(* synthesize *)
module mkAdder8Bit ( Ifc_adder#(8));
    let ifc();
    mkAdder _temp(ifc);
    return ifc;
endmodule 

endpackage

/*
TEST CASES

a = 0 10000110 111 0110 0100 0111 0000 0000
b = 0 10000010 101 0011 0011 1000 1101 1101
res = 0 10000111 000 0001 1011 1101 0100 0111

a = 0 01111000 110 1011 0111 0000 0010 0000
b = 1 01111011 000 1011 0001 1011 1000 0110
res = 1 01111010 101 1011 0101 1011 0000 0100
*/

//*************************************************************************
// END OF FILE
//*************************************************************************