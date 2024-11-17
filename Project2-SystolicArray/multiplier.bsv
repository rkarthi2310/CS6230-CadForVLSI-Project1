//*************************************************************************
// CS6230 CAD FOR VLSI PROJECT 2: SYSTOLIC ARRAY 
//
// FILE: multiplier.bsv
//
// AUTHORS: Karthikeyan R CS23S039
//          Arun Prabakar CS23D012
//
//*************************************************************************

package multiplier;

import adder::*;
import Vector::*;

interface Ifc_multiplier#(numeric type n);
    method ActionValue#(Bit#(TMul#(n,2))) mul (Bit#(n) x, Bit#(n) y);
endinterface

//(* synthesize *)
module mkMultiplierSigned (Ifc_multiplier#(n))
provisos(Add#(1, a__, TMul#(n,2)),Add#(b__, n, TMul#(n, 2)));

    Integer n1 = valueOf(n);
    Integer n2 = valueOf(TMul#(n, 2));
    Ifc_adder#(TMul#(n,2)) ifc_add <- mkAdder;

    method ActionValue#(Bit#(TMul#(n,2))) mul (Bit#(n) a, Bit#(n) b);

        // a - Multiplicand
        // b - Multiplier
        Bit#(TMul#(n, 2)) op1 = signExtend(a);
        Bit#(TMul#(n, 2)) op2 = signExtend(b);

        Bit#(TMul#(n, 2)) product = 0;

        Vector#(TMul#(n, 2), Bit#(TMul#(n, 2))) product_temp = replicate(0);
        Vector#(TMul#(n, 2), Bit#(TMul#(n, 2))) multiplicand_temp = replicate(0);
        Vector#(TMul#(n, 2), Bit#(1)) carry_temp = replicate(0);

        Integer i = 1;
        Integer j = 0;

        for(j=0; j<n2; j=j+1)
        begin
            multiplicand_temp[j] = (op2[j] == 1'b1)?op1:0;
            //$display ("multiplicand[%d] = %32b", j, multiplicand_temp[j]);
        end
        
        product_temp[0] = multiplicand_temp[0];
        //$display ("product_temp[%d] = %32b", 0, product_temp[0]);
        carry_temp[0] = 1'b0;
        //$display ("carry_temp[%d] = %32b", 0, carry_temp[0]);
        product[0] = product_temp[0][0];
        //$display ("product[%d] = %32b", 0, product[0]);

        for(i=1; i<n2; i=i+1)
        begin
            let adder_return <- ifc_add.add(multiplicand_temp[i], {carry_temp[i-1], product_temp[i-1][n2-1:1]}, 1'b0);
            carry_temp[i] = adder_return[n2];
            product_temp[i] = adder_return[n2-1:0];
            product[i] = product_temp[i][0];
            //$display ("product_temp[%d] = %32b", i, product_temp[i]);
            //$display ("carry_temp[%d] = %32b", i, carry_temp[i]);
            //$display ("product[%d] = %32b", i, product[i]);
        end

        //$display ("product = %32b", product);
        return product; 
    endmethod

endmodule

module mkMultiplierUnsigned (Ifc_multiplier#(n))
provisos(Add#(a__, n, TMul#(n, 2)), Add#(1, b__, n));

    Integer n1 = valueOf(n);
    Ifc_adder#(n) ifc_add <- mkAdder;

    method ActionValue#(Bit#(TMul#(n,2))) mul (Bit#(n) a, Bit#(n) b);
            
        // a - Multiplicand
        // b - Multiplier
        Bit#(TMul#(n, 2)) product = 0;

        Vector#(n, Bit#(n)) product_temp = replicate(0);
        Vector#(n, Bit#(n)) multiplicand_temp = replicate(0);
        Vector#(n, Bit#(1)) carry_temp = replicate(0);

        Integer i = 1;
        Integer j = 0;

        for(j=0; j<n1; j=j+1)
        begin
            multiplicand_temp[j] = (b[j] == 1'b1)?a:0;
            //$display ("multiplicand[%d] = %32b", j, multiplicand_temp[j]);
        end
        
        product_temp[0] = multiplicand_temp[0];
        //$display ("product_temp[%d] = %32b", 0, product_temp[0]);
        carry_temp[0] = 1'b0;
        //$display ("carry_temp[%d] = %32b", 0, carry_temp[0]);
        product[0] = product_temp[0][0];
        //$display ("product[%d] = %32b", 0, product[0]);

        for(i=1; i<n1; i=i+1)
        begin
            let adder_return <- ifc_add.add(multiplicand_temp[i], {carry_temp[i-1], product_temp[i-1][n1-1:1]}, 1'b0);
            carry_temp[i] = adder_return[n1];
            product_temp[i] = adder_return[n1-1:0];
            product[i] = product_temp[i][0];
            //$display ("product_temp[%d] = %32b", i, product_temp[i]);
            //$display ("carry_temp[%d] = %32b", i, carry_temp[i]);
            //$display ("product[%d] = %32b", i, product[i]);
        end

        Bit#(n) temp_val = {carry_temp[n1-1], product_temp[n1-1][n1-1:1]}; 
        //$display ("temp_val = ", temp_val);
        product[(2*n1)-1:n1] = temp_val;
        //$display ("product = %32b", product);
        return product; 
    endmethod

endmodule

//(* synthesize *)
module mkTb ( );
    let ifc <- mkMultiplier20Bit;

    rule end_tb;
        let ans = ifc.mul(20'd456, 20'd1907);
        $display ("The answer is: %32b", ans);
        $finish (0);
    endrule

endmodule: mkTb

//(* synthesize *)
module mkMultiplier20Bit ( Ifc_multiplier#(20));
    let ifc();
    mkMultiplierSigned _temp(ifc);
    return ifc;
endmodule   

endpackage

//*************************************************************************
// END OF FILE
//*************************************************************************