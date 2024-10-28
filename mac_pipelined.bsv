//*************************************************************************
// CS6230 CAD FOR VLSI PROJECT 1: MULTIPLY-ACCUMULATE (MAC) UNIT 
//
// FILE: mac_pipelined.bsv
//
// AUTHORS: Karthikeyan R CS23S039
//          Arun Prabakar CS23D012
//
//*************************************************************************

package mac_pipelined;

import adder::*;
import multiplier::*;
import fp_adder::*;
import fp_multiplier::*;
import Vector::*;
import FIFO::*;

interface Ifc_mac_pipelined;
    method Action set_inputs (Bit#(1) s1_or_s2_in, Bit#(16) a_in, Bit#(16) b_in, Bit#(32) c_in);
    method Bit#(32) get_result;
endinterface

(* synthesize *)
module mkMacPipelined (Ifc_mac_pipelined);

    let ifc_multiplier <- mkMultiplier8Bit;
    let ifc_adder <- mkAdder32Bit;
    let ifc_fpmultiplier <- mkFpMultiplier;
    let ifc_fpadder <- mkFpAdder;

    // Stage 1 registers
    FIFO#(Bit#(16)) a <- mkFIFO;
    FIFO#(Bit#(16)) b <- mkFIFO;
    FIFO#(Bit#(32)) c_1 <- mkFIFO;
    FIFO#(Bit#(1)) s1_or_s2_1 <- mkFIFO;

    // Stage 2 regsiters
    FIFO#(Bit#(32)) mac_intermediate_AB <- mkFIFO;
    FIFO#(Bit#(32)) c_2 <- mkFIFO;
    FIFO#(Bit#(1)) s1_or_s2_2 <- mkFIFO;

    // Output
    Wire#(Bit#(32)) result <- mkWire;
   
    rule perform_mac_stage1;
        Bit#(8) mac_int32_A = a.first[7:0]; 
        Bit#(16) mac_fp32_A = a.first[15:0];
        a.deq;

        Bit#(8) mac_int32_B = b.first[7:0]; 
        Bit#(16) mac_fp32_B = b.first[15:0];
        b.deq;

        Bit#(32) c = c_1.first; 
        c_1.deq;

        Bit#(1) s1_or_s2 = s1_or_s2_1.first; 
        s1_or_s2_1.deq;

        Bit#(16) mac_int32_product_AB = 0;
        Bit#(33) mac_int32_mac_result = 0;

        Bit#(32) mac_fp32_product_AB = 0;

        //$display ("A is: %32b", mac_int32_A);
        //$display ("B is: %32b", mac_int32_B);

        if(s1_or_s2 == 1'b1)
        begin
            mac_int32_product_AB <- ifc_multiplier.mul(mac_int32_A, mac_int32_B);
            Bit#(32) pr = signExtend(mac_int32_product_AB);
            mac_intermediate_AB.enq(signExtend(mac_int32_product_AB));
        end
        else
        begin
            mac_fp32_product_AB <- ifc_fpmultiplier.fp_mul(mac_fp32_A, mac_fp32_B);
            mac_intermediate_AB.enq(mac_fp32_product_AB);
        end
        c_2.enq(c);
        s1_or_s2_2.enq(s1_or_s2);

    endrule

    rule perform_mac_stage2;

        Bit#(32) c = c_2.first;
        c_2.deq;
        
        Bit#(1) s1_or_s2 = s1_or_s2_2.first; 
        s1_or_s2_2.deq;

        Bit#(32) mac_int32_product_AB = mac_intermediate_AB.first;
        Bit#(32) mac_fp32_product_AB = mac_intermediate_AB.first;
        mac_intermediate_AB.deq;

        Bit#(33) mac_int32_mac_result = 0;
        Bit#(32) mac_result = 0;

        //$display ("mac_intermediate_AB is: %32b", mac_intermediate_AB.first);

        if(s1_or_s2 == 1'b1)
        begin
            mac_int32_mac_result <- ifc_adder.add(mac_int32_product_AB, c, 1'b0);
            mac_result = mac_int32_mac_result[31:0];
        end
        else
        begin
            mac_result <- ifc_fpadder.fp_add(mac_fp32_product_AB, c);
        end

        result <= mac_result;

    endrule

    method Action set_inputs (Bit#(1) s1_or_s2_in, Bit#(16) a_in, Bit#(16) b_in, Bit#(32) c_in);
        a.enq(a_in);
        b.enq(b_in);
        c_1.enq(c_in);
        s1_or_s2_1.enq(s1_or_s2_in);
    endmethod

    method Bit#(32) get_result;
        return result;
    endmethod

endmodule

//(* synthesize *)
module mkTb ( );
    let ifc <- mkMacPipelined;
    Reg#(Bit#(32)) i <- mkReg(0);

    rule stage1(i == 0);
        $display ("---------------- Cycle %d start ----------------------", i);
        ifc.set_inputs (1'b1, 56, 32, -1973);
    endrule

    rule stage2;
        $display ("---------------- Cycle %d start ----------------------", i);
        let ans = ifc.get_result;
        $display ("The answer is: %32b", ans);
        $finish (0);
    endrule

    rule counter;
        i <= i+1;
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



