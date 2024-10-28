//*************************************************************************
// CS6230 CAD FOR VLSI PROJECT 1: MULTIPLY-ACCUMULATE (MAC) UNIT 
//
// FILE: mac.bsv
//
// AUTHORS: Karthikeyan R CS23S039
//          Arun Prabakar CS23D012
//
//*************************************************************************

package mac;

import adder::*;
import multiplier::*;
import fp_adder::*;
import fp_multiplier::*;
import Vector::*;

interface Ifc_mac;
    method ActionValue#(Bit#(32)) mac (Bit#(1) s1_or_s2, Bit#(16) a, Bit#(16) b, Bit#(32) c);
endinterface

(* synthesize *)
module mkMac (Ifc_mac);

    let ifc_multiplier <- mkMultiplier8Bit;
    let ifc_adder <- mkAdder32Bit;
    let ifc_fpmultiplier <- mkFpMultiplier;
    let ifc_fpadder <- mkFpAdder;

    method ActionValue#(Bit#(32)) mac (Bit#(1) s1_or_s2, Bit#(16) a, Bit#(16) b, Bit#(32) c);

        Bit#(8) mac_int32_A = a[7:0];
        Bit#(8) mac_int32_B = b[7:0];
        Bit#(16) mac_int32_product_AB = 0;
        Bit#(33) mac_int32_mac_result = 0;
        Bit#(16) mac_fp32_A = a[15:0];
        Bit#(16) mac_fp32_B = b[15:0];
        Bit#(32) mac_fp32_product_AB = 0;
        Bit#(32) mac_result = 0; 

        //$display ("A is: %32b", mac_int32_A);
        //$display ("B is: %32b", mac_int32_B);

        if(s1_or_s2 == 1'b1)
        begin
            mac_int32_product_AB <- ifc_multiplier.mul(mac_int32_A, mac_int32_B);
            Bit#(32) pr = signExtend(mac_int32_product_AB);
            $display ("AB is: %32b", pr);
            mac_int32_mac_result <- ifc_adder.add(signExtend(mac_int32_product_AB), c, 1'b0);
            mac_result = mac_int32_mac_result[31:0];
        end
        else
        begin
            mac_fp32_product_AB <- ifc_fpmultiplier.fp_mul(mac_fp32_A, mac_fp32_B);
            mac_result <- ifc_fpadder.fp_add(mac_fp32_product_AB, c);
        end
        return mac_result; 
    endmethod

endmodule

//(* synthesize *)
module mkTb ( );
    let ifc <- mkMac;

    rule theUltimateAnswer;
        let ans= ifc.mac (1'b1, -56, 32, -1973);
        $display ("The answer is: %32b", ans);
        //let ans = ifc.mac (1'b0, 16'b0100000110011101, 16'b0100000110111111, 32'b01000011101011001111110101110000);
        //$display ("The answer is: %32b", ans);
        $finish (0);
    endrule

endmodule: mkTb

//(* synthesize *)
module mkMultiplier8Bit ( Ifc_multiplier#(8));
    let ifc();
    mkMultiplierSigned _temp(ifc);
    return ifc;
endmodule    

//(* synthesize *)
module mkAdder32Bit ( Ifc_adder#(32));
    let ifc();
    mkAdder _temp(ifc);
    return ifc;
endmodule 

endpackage

//*************************************************************************
// END OF FILE
//*************************************************************************