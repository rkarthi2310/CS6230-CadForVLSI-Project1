//*************************************************************************
// CS6230 CAD FOR VLSI PROJECT 1: MULTIPLY-ACCUMULATE (MAC) UNIT 
//
// FILE: fp_multiplier.bsv
//
// AUTHORS: Karthikeyan R CS23S039
//          Arun Prabakar CS23D012
//
//*************************************************************************

package fp_multiplier;

import adder::*;
import multiplier::*;

interface Ifc_fpmultiplier;
    method ActionValue#(Bit#(32)) fp_mul (Bit#(16) a, Bit#(16) b);
endinterface

//(* synthesize *)
module mkFpMultiplier (Ifc_fpmultiplier);

    let ifc_multiplier8 <- mkMultiplier8Bit;
    let ifc_adder8_1 <- mkAdder8Bit;
    let ifc_adder8_2 <- mkAdder8Bit;
    let ifc_adder8_3 <- mkAdder8Bit;
    let ifc_adder8_4 <- mkAdder8Bit;
    let ifc_adder8_5 <- mkAdder8Bit;
    
    method ActionValue#(Bit#(32)) fp_mul (Bit#(16) a, Bit#(16) b);

        Bit#(1) output_sign = 0;
        
        Bit#(8) mantissa1 = 0;
        Bit#(8) mantissa2 = 0;
        
        Bit#(8) exponent1 = 0;
        Bit#(8) exponent2 = 0;

        Bit#(9) rounded_up_mantissa = 0;
        Bit#(9) intermediate_output_exponent_1 = 0;
        Bit#(9) intermediate_output_exponent_2 = 0;
        Bit#(9) intermediate_output_exponent_3 = 0;
        Bit#(9) intermediate_output_exponent_4 = 0;
    
        Bit#(16) intermediate_mul_mantissa = 0;
        Bit#(1) normalised = 0;
        Bit#(16) normalised_mul_mantissa = 0;
        Bit#(1) rounding_carry = 0;
        Bit#(16) rounded_mul_mantissa = 0;
    
        Bit#(8) output_exponent = 0;
        Bit#(23) output_mantissa = 0;
        Bit#(32) mul_result = 0;

        //$display ("op1 = %32b", a);
        //$display ("op2 = %32b", b);

        // Calculate output sign
        output_sign = a[15] ^ b[15];
        //$display ("output_sign = %32b", output_sign);

        // Extract exponents of the operands.
        exponent1 = a[14:7];
        exponent2 = b[14:7];
        //$display ("exp1 = %32b", exponent1);
        //$display ("exp2 = %32b", exponent2);

        // Extract operand mantissa. Account for the implicit bit 
        // by checking if its a normal or a subnormal number.
        mantissa1 = (|exponent1 == 1)?{1'b1, a[6:0]}:{1'b0, a[6:0]};
        mantissa2 = (|exponent2 == 1)?{1'b1, b[6:0]}:{1'b0, b[6:0]};
        //$display ("mantissa1 = %32b", mantissa1);
        //$display ("mantissa2 = %32b", mantissa2);

        // Multiplication
        intermediate_mul_mantissa <- ifc_multiplier8.mul(mantissa1, mantissa2);
        //$display ("intermediate_mul_mantissa = %32b", intermediate_mul_mantissa);

        // Check whether normalisation is needed
        normalised = (intermediate_mul_mantissa[15] == 1'b1) ? 1'b1 : 1'b0;
        normalised_mul_mantissa = (normalised == 1'b1) ? intermediate_mul_mantissa : intermediate_mul_mantissa << 1;
        //$display ("normalised = %32b", normalised);

        // Rounding
        rounded_up_mantissa <- ifc_adder8_4.add(normalised_mul_mantissa[15:8], zeroExtend(1'b1), 1'b0);
        rounded_mul_mantissa = (normalised_mul_mantissa[7] == 1'b1)?(|normalised_mul_mantissa[6:0] == 1'b1)?{rounded_up_mantissa[7:0], 8'b0}:(normalised_mul_mantissa[8] == 1'b1)?{rounded_up_mantissa[7:0], 8'b0}:{normalised_mul_mantissa[15:8], 8'b0}:{normalised_mul_mantissa[15:8], 8'b0};
        rounding_carry = (normalised_mul_mantissa[7] == 1'b1)?(|normalised_mul_mantissa[6:0] == 1'b1)?rounded_up_mantissa[8]:(normalised_mul_mantissa[8] == 1'b1)?rounded_up_mantissa[8]:1'b0:1'b0;
        //$display ("rounded_mul_mantissa = %32b", rounded_mul_mantissa);

        // Calculate output exponent
        intermediate_output_exponent_1 <- ifc_adder8_1.add(exponent1, exponent2, 1'b0);
        intermediate_output_exponent_2 <- ifc_adder8_2.add(intermediate_output_exponent_1[7:0], 8'd127, 1'b1);
        intermediate_output_exponent_3 <- ifc_adder8_3.add(intermediate_output_exponent_2[7:0], zeroExtend(normalised), 1'b0);
        intermediate_output_exponent_4 <- ifc_adder8_4.add(intermediate_output_exponent_3[7:0], zeroExtend(rounding_carry), 1'b0);
        output_exponent = intermediate_output_exponent_4[7:0];
        //$display ("output exponent = %32b", output_exponent);

        // Output mantissa
        output_mantissa = zeroExtend(rounded_mul_mantissa[14:0]) << 8; 
        //$display ("output_mantissa = %32b", output_mantissa);

        // Assign result
        mul_result = {output_sign, output_exponent, output_mantissa};
        //$display ("mul_result = %32b", mul_result);

        return mul_result;
        
    endmethod
endmodule


//(* synthesize *)
module mkTb (Empty);
    Ifc_fpmultiplier ifc <- mkFpMultiplier;

    rule test;
        Bit#(32) ans;
        //ans <- ifc.fp_mul(16'b0100001010110000, 16'b0100001100001011);
        //$display ("The answer is: %0b", ans);
        ans <- ifc.fp_mul(16'b1100011001000010, 16'b0100001100011110);
        $display ("The answer is: %32b", ans);
        $finish (0);
    endrule

endmodule: mkTb


//(* synthesize *)
module mkMultiplier8Bit ( Ifc_multiplier#(8));
    let ifc();
    mkMultiplierUnsigned _temp(ifc);
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

a = 0 10000101 0110000
b = 0 10000110 0001011
res = 0 10001100 0111111 0000 0000 0000 0000

a = 1 10001100 1000010
b = 0 10000110 0011110
res = 1 10010011 1101111 0000 0000 0000 0000
*/

//*************************************************************************
// END OF FILE
//*************************************************************************