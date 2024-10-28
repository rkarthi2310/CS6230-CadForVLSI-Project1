//*************************************************************************
// CS6230 CAD FOR VLSI PROJECT 1: MULTIPLY-ACCUMULATE (MAC) UNIT 
//
// FILE: adder.bsv
//
// AUTHORS: Karthikeyan R CS23S039
//          Arun Prabakar CS23D012
//
//*************************************************************************

package adder;

interface Ifc_adder#(numeric type n);
    method ActionValue#(Bit#(TAdd#(n,1))) add (Bit#(n) x, Bit#(n) y, Bit#(1) add_or_sub);
endinterface

function Bit#(2) half_adder (Bit#(1) x, Bit#(1) y);
    Bit#(1) s;
    Bit#(1) c;

    s = x ^ y;
    c = x & y;

    return {c, s};
endfunction

function Bit#(2) full_adder (Bit#(1) x, Bit#(1) y, Bit#(1) c_in);
    Bit#(1) s;
    Bit#(1) c_out;

    s = (x ^ y) ^ c_in;
    c_out = (y & c_in) | (x & y) | (x & c_in);

    return {c_out, s};
endfunction

//(* synthesize *)
module mkAdder (Ifc_adder#(n));

    Integer n1 = valueOf(n);
  
    method ActionValue#(Bit#(TAdd#(n,1))) add (Bit#(n) a, Bit#(n) b, Bit#(1) add_or_sub);

        Bit#(n) carry = 0;
        Bit#(1) carry_out = 0;
        Bit#(n) answer = 0;
        Bit#(n) op2 = (add_or_sub == 1'b1)?(~b):b;        
        
        Integer i = 0;
        Bit#(2) adder_return = 0;

        for(i=0; i<n1; i=i+1)
        begin
            if(i==0)
            begin
                adder_return = full_adder(a[0], op2[0], add_or_sub);
                //$display ("a[0] = %1b, b[0] = %1b", a[0], b[0]);
                answer[0] = adder_return[0];
                carry[0] = adder_return[1];
                //$display ("answer[0] = %1b, carry[0] = %1b", adder_return[1], adder_return[0]);
            end
            else
            begin
                adder_return = full_adder(a[i], op2[i], carry[i-1]);
                answer[i] = adder_return[0];
                carry[i] = adder_return[1];
                //$display ("a[i] = %1b, b[i] = %1b", a[i], b[i]);
                //$display ("answer[i] = %1b, carry[i] = %1b", adder_return[1], adder_return[0]);
            end
        end

        carry_out = carry[n1-1];

        return {carry_out, answer}; 
    endmethod

endmodule

//(* synthesize *)
module mkTb ( );
    let ifc <- mkAdder20Bit;

    rule ans_tb;
        let ans <- ifc.add (20'd1233, 20'd323, 1'b1);
        let ans_disp = ans[19:0];
        $display ("The answer is: %0d", ans_disp);
        $finish (0);
    endrule

endmodule: mkTb

//(* synthesize *)
module mkAdder20Bit ( Ifc_adder#(20));
    let ifc();
    mkAdder _temp(ifc);
    return ifc;
endmodule    

endpackage

//*************************************************************************
// END OF FILE
//*************************************************************************