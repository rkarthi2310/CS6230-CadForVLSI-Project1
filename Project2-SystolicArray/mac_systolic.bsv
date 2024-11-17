//*************************************************************************
// CS6230 CAD FOR VLSI PROJECT 2: SYSTOLIC ARRAY 
//
// FILE: mac_systolic.bsv
//
// AUTHORS: Karthikeyan R CS23S039
//          Arun Prabakar CS23D012
//
//*************************************************************************

package mac_systolic;

import adder::*;
import multiplier::*;
import fp_adder::*;
import fp_multiplier::*;
import Vector::*;
import FIFO::*;

interface Ifc_mac_systolic;
    method Action set_state (Bit#(1) transfer_b_state);
    method Action set_a (Bit#(16) a_in);
    method Action set_b (Bit#(16) b_in);
    method Action set_c (Bit#(32) c_in);
    method Action set_s1_or_s2 (Bit#(1) s1_or_s2_in);
    method Bit#(32) get_result;
    method Bit#(16) get_a;
    method Bit#(16) get_b;
    method Bit#(1) get_s1_or_s2;
endinterface

(* synthesize *)
module mkMacSystolic (Ifc_mac_systolic);

    let ifc_multiplier <- mkMultiplier8Bit;
    let ifc_adder <- mkAdder32Bit;
    let ifc_fpmultiplier <- mkFpMultiplier;
    let ifc_fpadder <- mkFpAdder;

    // Counter
    Reg#(Bit#(32)) counter <- mkReg(0);

    // State of the MAC unit
    Reg#(Bit#(1)) transfer_b <- mkReg(0);

    // Stage 1 registers
    FIFO#(Bit#(16)) a_1 <- mkFIFO;
    FIFO#(Bit#(16)) b_1 <- mkFIFO;
    FIFO#(Bit#(32)) c_1 <- mkFIFO;
    FIFO#(Bit#(1)) s1_or_s2_1 <- mkFIFO;

    // Stage 2 regsiters
    FIFO#(Bit#(32)) mac_intermediate_AB <- mkFIFO;
    FIFO#(Bit#(16)) a_2 <- mkFIFO;
    FIFO#(Bit#(32)) c_2 <- mkFIFO;
    FIFO#(Bit#(1)) s1_or_s2_2 <- mkFIFO;

    // Output
    Wire#(Bit#(32)) result <- mkWire;
    Wire#(Bit#(16)) a_out <- mkWire;
    Wire#(Bit#(16)) b_out <- mkWire;
    Wire#(Bit#(1)) s1_or_s2_out <- mkWire;
   
    rule count_up;
        counter <= counter+1;
    endrule

    rule perform_mac_stage1(transfer_b == 0);
        Bit#(8) mac_int32_A = a_1.first[7:0]; 
        Bit#(16) mac_fp32_A = a_1.first[15:0];
        Bit#(16) a_temp = a_1.first[15:0];
        a_1.deq;

        Bit#(8) mac_int32_B = b_1.first[7:0]; 
        Bit#(16) mac_fp32_B = b_1.first[15:0];
        Bit#(16) b_temp = b_1.first[15:0];

        Bit#(32) c = c_1.first; 
        c_1.deq;

        Bit#(1) s1_or_s2 = s1_or_s2_1.first; 
        s1_or_s2_1.deq;

        Bit#(16) mac_int32_product_AB = 0;
        Bit#(33) mac_int32_mac_result = 0;

        Bit#(32) mac_fp32_product_AB = 0;

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
        a_2.enq(a_temp);
        c_2.enq(c);
        s1_or_s2_2.enq(s1_or_s2);

    endrule

    rule perform_mac_stage2(transfer_b == 0);
        Bit#(32) c = c_2.first;
        c_2.deq;
        
        Bit#(1) s1_or_s2 = s1_or_s2_2.first; 

        Bit#(32) mac_int32_product_AB = mac_intermediate_AB.first;
        Bit#(32) mac_fp32_product_AB = mac_intermediate_AB.first;
        mac_intermediate_AB.deq;

        Bit#(33) mac_int32_mac_result = 0;
        Bit#(32) mac_result = 0;

        if(s1_or_s2 == 1'b1)
        begin
            mac_int32_mac_result <- ifc_adder.add(mac_int32_product_AB, c, 1'b0);
            mac_result = mac_int32_mac_result[31:0];
        end
        else
        begin
            mac_result <- ifc_fpadder.fp_add(mac_fp32_product_AB, c);
        end

        a_out <= a_2.first;
        a_2.deq;

        s1_or_s2_out <= s1_or_s2_2.first;
        s1_or_s2_2.deq;

        result <= mac_result;

    endrule

    rule send_b(transfer_b == 1);
        b_out <= b_1.first;
        b_1.deq;
    endrule

    method Action set_state (Bit#(1) transfer_b_state);
        transfer_b <= transfer_b_state;
    endmethod

    method Action set_a (Bit#(16) a_in);
        a_1.enq(a_in);
    endmethod

    method Action set_b (Bit#(16) b_in);
        b_1.enq(b_in);
    endmethod

    method Action set_c (Bit#(32) c_in);
        c_1.enq(c_in);
    endmethod

    method Action set_s1_or_s2 (Bit#(1) s1_or_s2_in);
        s1_or_s2_1.enq(s1_or_s2_in);
    endmethod

    method Bit#(32) get_result;
        return result;
    endmethod

    method Bit#(16) get_a;
        return a_out;
    endmethod   

    method Bit#(16) get_b;
        return b_out;
    endmethod

    method Bit#(1) get_s1_or_s2;
        return s1_or_s2_out;        
    endmethod

endmodule

//(* synthesize *)
module mkTb ( );
    let ifc <- mkMacSystolic;
    Reg#(Bit#(32)) i <- mkReg(0);

    rule stage1(i == 0);
        $display ("---------------- Cycle %d start ----------------------", i);
        ifc.set_state(1'b1);
        ifc.set_s1_or_s2(1'b1);
        ifc.set_a(56);
        ifc.set_b(32);
        ifc.set_c(-1973);
    endrule

    rule print_b;
        $display ("---------------- Cycle %d start ----------------------", i);
        let b = ifc.get_b;
        $display ("The answer is: %32b", b);
        ifc.set_state(1'b0);
        ifc.set_b(32);
        //$finish (0);
    endrule

    rule stage2;
        $display ("---------------- Cycle %d start ----------------------", i);
        let ans = ifc.get_result;
        $display ("The answer is: %32b", ans);
        let a = ifc.get_a;
        $display ("The answer is: %32b", a);
        let b = ifc.get_b;
        $display ("The answer is: %32b", b);
        let s1_or_s2 = ifc.get_s1_or_s2;
        $display ("The answer is: %32b", s1_or_s2);
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