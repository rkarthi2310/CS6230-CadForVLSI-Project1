//*************************************************************************
// CS6230 CAD FOR VLSI PROJECT 2: SYSTOLIC ARRAY 
//
// FILE: systolic.bsv
//
// AUTHORS: Karthikeyan R CS23S039
//          Arun Prabakar CS23D012
//
//*************************************************************************

package systolic;

import mac_systolic::*;
import Vector::*;
import FIFO::*;

interface Ifc_systolic;
    method Action set_A_matrix (Vector#(4, Bit#(16)) a_matrix);
    method Action set_B_matrix (Vector#(4, Bit#(16)) b_matrix);
    method Action set_C_row1 (Bit#(32) c_val);
    method Action set_s1_or_s2_row1 (Bit#(1) s1_or_s2_in);
    method Action initialise_systolic (Bit#(1) s1_or_s2_in);
    method Action set_state_systolic (Bit#(1) state_in);
    method ActionValue#(Vector#(4, Bit#(32))) get_result;
endinterface

interface Ifc_topsystolic;
    method Action set_A_matrix_in (Vector#(4, Vector#(4, Bit#(16))) a_matrix_in);
    method Action set_B_matrix_in (Vector#(4, Vector#(4, Bit#(16))) b_matrix_in);
    method Action set_s1_or_s2_top (Bit#(1) s1_or_s2_in);
    method Vector#(4, Vector#(4, Bit#(32))) get_matrix_mul_result;
endinterface

(* synthesize *)
module mkSystolic (Ifc_systolic);

    // [0][0]  [0][1]  [0][2]  [0][3]
    // [1][0]  [1][1]  [1][2]  [1][3]
    // [2][0]  [2][1]  [2][2]  [2][3]
    // [3][0]  [3][1]  [3][2]  [3][3]
    Vector#(4, Vector#(4, Ifc_mac_systolic)) systolic_array <- replicateM(replicateM(mkMacSystolic));

    // Counter
    Reg#(Bit#(32)) counter <- mkReg(0);

    rule count_up;
        counter <= counter+1;
    endrule

    rule shift_b_row1;
        Vector#(4, Bit#(16)) b_internal;
        for(Integer j = 0; j < 4; j = j+1)
        begin
            // B flows from top to bottom
            b_internal[j] = systolic_array[0][j].get_b;
            systolic_array[1][j].set_b(b_internal[j]);
        end
    endrule

    rule shift_b_row2;
        Vector#(4, Bit#(16)) b_internal;
        for(Integer j = 0; j < 4; j = j+1)
        begin
            // B flows from top to bottom
            b_internal[j] = systolic_array[1][j].get_b;
            systolic_array[2][j].set_b(b_internal[j]);
        end
    endrule

    rule shift_b_row3;
        Vector#(4, Bit#(16)) b_internal;
        for(Integer j = 0; j < 4; j = j+1)
        begin
            // B flows from top to bottom
            b_internal[j] = systolic_array[2][j].get_b;
            systolic_array[3][j].set_b(b_internal[j]);
        end
    endrule

    rule shift_c_row1;
        Vector#(4, Bit#(32)) c_internal;
        Vector#(4, Bit#(1)) s1_or_s2_internal;
        
        for(Integer j = 0; j < 4; j = j+1)
        begin
            // C flows from top to bottom
            c_internal[j] = systolic_array[0][j].get_result;
            systolic_array[1][j].set_c(c_internal[j]);

            // s1_or_s2
            s1_or_s2_internal[j] = systolic_array[0][j].get_s1_or_s2;
            systolic_array[1][j].set_s1_or_s2(s1_or_s2_internal[j]);
        end
    endrule

    rule shift_c_row2;
        Vector#(4, Bit#(32)) c_internal;
        Vector#(4, Bit#(1)) s1_or_s2_internal;
        
        for(Integer j = 0; j < 4; j = j+1)
        begin
            // C flows from top to bottom
            c_internal[j] = systolic_array[1][j].get_result;
            systolic_array[2][j].set_c(c_internal[j]);

            // s1_or_s2
            s1_or_s2_internal[j] = systolic_array[1][j].get_s1_or_s2;
            systolic_array[2][j].set_s1_or_s2(s1_or_s2_internal[j]);
        end
    endrule

    rule shift_c_row3;
        Vector#(4, Bit#(32)) c_internal;
        Vector#(4, Bit#(1)) s1_or_s2_internal;

        for(Integer j = 0; j < 4; j = j+1)
        begin
            // C flows from top to bottom
            c_internal[j] = systolic_array[2][j].get_result;
            systolic_array[3][j].set_c(c_internal[j]);

            // s1_or_s2
            s1_or_s2_internal[j] = systolic_array[2][j].get_s1_or_s2;
            systolic_array[3][j].set_s1_or_s2(s1_or_s2_internal[j]);
        end
    endrule


    rule shift_a_column1;
        Vector#(4, Bit#(16)) a_internal;
        for(Integer j = 0; j < 4; j = j+1)
        begin
            // A flows from left to right
            a_internal[j] = systolic_array[j][0].get_a;
            systolic_array[j][1].set_a(a_internal[j]);
        end
    endrule

    rule shift_a_column2;
        Vector#(4, Bit#(16)) a_internal;
        for(Integer j = 0; j < 4; j = j+1)
        begin
            // A flows from left to right
            a_internal[j] = systolic_array[j][1].get_a;
            systolic_array[j][2].set_a(a_internal[j]);
        end
    endrule

    rule shift_a_column3;
        Vector#(4, Bit#(16)) a_internal;
        for(Integer j = 0; j < 4; j = j+1)
        begin
            // A flows from left to right
            a_internal[j] = systolic_array[j][2].get_a;
            systolic_array[j][3].set_a(a_internal[j]);
        end
    endrule

    method Action set_A_matrix (Vector#(4, Bit#(16)) a_matrix);
        for(Integer i = 0; i < 4; i = i+1)
        begin
            systolic_array[i][0].set_a(a_matrix[i]);
        end
    endmethod

    method Action set_B_matrix (Vector#(4, Bit#(16)) b_matrix);
        for(Integer i = 0; i < 4; i = i+1)
        begin
            systolic_array[0][i].set_b(b_matrix[i]);
        end
    endmethod

    method Action set_C_row1 (Bit#(32) c_val);
        for(Integer i = 0; i < 4; i = i+1)
        begin
            systolic_array[0][i].set_c(c_val);
        end
    endmethod

    method Action set_s1_or_s2_row1 (Bit#(1) s1_or_s2_in);
        for(Integer i = 0; i < 4; i = i+1)
        begin
            systolic_array[0][i].set_s1_or_s2(s1_or_s2_in);
        end
    endmethod

    method Action initialise_systolic (Bit#(1) s1_or_s2_in);
        for(Integer i = 0; i < 4; i = i+1)
        begin
            for(Integer j = 0; j < 4; j = j+1)
            begin
                systolic_array[i][j].set_s1_or_s2(s1_or_s2_in);
                systolic_array[i][j].set_c(32'b0);
            end
        end

        for(Integer i = 0; i < 4; i = i+1)
        begin
            for(Integer j = 1; j < 4; j = j+1)
            begin
                systolic_array[i][j].set_a(16'b0);
            end
        end
    endmethod

    method Action set_state_systolic (Bit#(1) state_in);
        for(Integer i = 0; i < 4; i = i+1)
        begin
            for(Integer j = 0; j < 4; j = j+1)
            begin
                systolic_array[i][j].set_state(state_in);
            end
        end
    endmethod

    method ActionValue#(Vector#(4, Bit#(32))) get_result;
        Vector#(4, Bit#(32)) result;
        for(Integer i = 0; i < 4; i = i+1)
        begin
            result[i] = systolic_array[3][i].get_result;
        end
        return result;
    endmethod

endmodule


(* synthesize *)
module mkTopSystolic (Ifc_topsystolic);

    let systolic_unit <- mkSystolic;
    Reg#(Bit#(32)) counter <- mkReg(0);
    Reg#(Bit#(1)) s1_or_s2_systolic <- mkReg(0);

    // [0][0]  [0][1]  [0][2]  [0][3]
    // [1][0]  [1][1]  [1][2]  [1][3]
    // [2][0]  [2][1]  [2][2]  [2][3]
    // [3][0]  [3][1]  [3][2]  [3][3]
    Vector#(4, Vector#(4, Reg#(Bit#(16)))) b_matrix_top <- replicateM(replicateM(mkReg(0)));
    
    // [0][0]  [1][0]  [2][0]  [3][0] .... [6][0]
    // [0][1]  [1][1]  [2][1]  [3][1] .... [6][1]
    // [0][2]  [1][2]  [2][2]  [3][2] .... [6][2]
    // [0][3]  [1][3]  [2][3]  [3][3] .... [6][3]
    Vector#(7, Vector#(4, Reg#(Bit#(16)))) a_matrix_top <- replicateM(replicateM(mkReg(0)));

    // [0][0]  [1][0]  [2][0]  [3][0] .... [6][0]
    // [0][1]  [1][1]  [2][1]  [3][1] .... [6][1]
    // [0][2]  [1][2]  [2][2]  [3][2] .... [6][2]
    // [0][3]  [1][3]  [2][3]  [3][3] .... [6][3]
    Vector#(7, Vector#(4, Reg#(Bit#(32)))) c_matrix_top <- replicateM(replicateM(mkReg(0)));

    rule b_row3(counter == 1);
        Vector#(4, Bit#(16)) temp;
        for(Integer i = 0; i < 4; i = i+1)
        begin
            temp[i] = b_matrix_top[3][i];
        end
        systolic_unit.set_state_systolic(1'b1);
        systolic_unit.initialise_systolic(s1_or_s2_systolic);
        systolic_unit.set_B_matrix(temp);
    endrule

    rule b_row2(counter == 2);
        Vector#(4, Bit#(16)) temp;
        for(Integer i = 0; i < 4; i = i+1)
        begin
            temp[i] = b_matrix_top[2][i];
        end
        systolic_unit.set_B_matrix(temp);
    endrule

    rule b_row1(counter == 3);
        Vector#(4, Bit#(16)) temp;
        for(Integer i = 0; i < 4; i = i+1)
        begin
            temp[i] = b_matrix_top[1][i];
        end
        systolic_unit.set_B_matrix(temp);
    endrule

    rule b_row0(counter == 4);
        Vector#(4, Bit#(16)) temp;
        for(Integer i = 0; i < 4; i = i+1)
        begin
            temp[i] = b_matrix_top[0][i];
        end
        systolic_unit.set_B_matrix(temp);
        systolic_unit.set_state_systolic(1'b0);
    endrule

    rule a_column0(counter == 4);
        Vector#(4, Bit#(16)) temp;
        for(Integer i = 0; i < 4; i = i+1)
        begin
            temp[i] = a_matrix_top[6][i];
        end
        systolic_unit.set_A_matrix(temp);
    endrule

    rule a_column1(counter == 6);
        Vector#(4, Bit#(16)) temp;
        for(Integer i = 0; i < 4; i = i+1)
        begin
            temp[i] = a_matrix_top[5][i];
        end
        systolic_unit.set_A_matrix(temp);
        systolic_unit.set_C_row1(32'b0);
        systolic_unit.set_s1_or_s2_row1(s1_or_s2_systolic);
    endrule

    rule a_column2(counter == 8);
        Vector#(4, Bit#(16)) temp;
        for(Integer i = 0; i < 4; i = i+1)
        begin
            temp[i] = a_matrix_top[4][i];
        end
        systolic_unit.set_A_matrix(temp);
        systolic_unit.set_C_row1(32'b0);
        systolic_unit.set_s1_or_s2_row1(s1_or_s2_systolic);
    endrule

    rule a_column3(counter == 10);
        Vector#(4, Bit#(16)) temp;
        for(Integer i = 0; i < 4; i = i+1)
        begin
            temp[i] = a_matrix_top[3][i];
        end
        systolic_unit.set_A_matrix(temp);
        systolic_unit.set_C_row1(32'b0);
        systolic_unit.set_s1_or_s2_row1(s1_or_s2_systolic);
    endrule

    rule a_column4(counter == 12);
        Vector#(4, Bit#(16)) temp;
        for(Integer i = 0; i < 4; i = i+1)
        begin
            temp[i] = a_matrix_top[2][i];
        end
        systolic_unit.set_A_matrix(temp);
        systolic_unit.set_C_row1(32'b0);
        systolic_unit.set_s1_or_s2_row1(s1_or_s2_systolic);
    endrule

    rule a_column5(counter == 14);
        Vector#(4, Bit#(16)) temp;
        for(Integer i = 0; i < 4; i = i+1)
        begin
            temp[i] = a_matrix_top[1][i];
        end
        systolic_unit.set_A_matrix(temp);
        systolic_unit.set_C_row1(32'b0);
        systolic_unit.set_s1_or_s2_row1(s1_or_s2_systolic);
    endrule

    rule a_column6(counter == 16);
        Vector#(4, Bit#(16)) temp;
        for(Integer i = 0; i < 4; i = i+1)
        begin
            temp[i] = a_matrix_top[0][i];
        end
        systolic_unit.set_A_matrix(temp);
        systolic_unit.set_C_row1(32'b0);
        systolic_unit.set_s1_or_s2_row1(s1_or_s2_systolic);
    endrule

    rule a_dummy1(counter == 18);
        Vector#(4, Bit#(16)) temp;
        for(Integer i = 0; i < 4; i = i+1)
        begin
            temp[i] = 0;
        end
        systolic_unit.set_A_matrix(temp);
        systolic_unit.set_C_row1(32'b0);
        systolic_unit.set_s1_or_s2_row1(s1_or_s2_systolic);
    endrule

    rule a_dummy2(counter == 20);
        Vector#(4, Bit#(16)) temp;
        for(Integer i = 0; i < 4; i = i+1)
        begin
            temp[i] = 0;
        end
        systolic_unit.set_A_matrix(temp);
        systolic_unit.set_C_row1(32'b0);
        systolic_unit.set_s1_or_s2_row1(s1_or_s2_systolic);
    endrule

    rule a_dummy3(counter == 22);
        Vector#(4, Bit#(16)) temp;
        for(Integer i = 0; i < 4; i = i+1)
        begin
            temp[i] = 0;
        end
        systolic_unit.set_A_matrix(temp);
        systolic_unit.set_C_row1(32'b0);
        systolic_unit.set_s1_or_s2_row1(s1_or_s2_systolic);
    endrule

    rule c_column6(counter == 12);
        Vector#(4, Bit#(32)) temp <- systolic_unit.get_result;
        for(Integer i = 0; i < 4; i = i+1)
        begin
            c_matrix_top[6][i] <= temp[i];
        end
    endrule

    rule c_column5(counter == 14);
        Vector#(4, Bit#(32)) temp <- systolic_unit.get_result;
        for(Integer i = 0; i < 4; i = i+1)
        begin
            c_matrix_top[5][i] <= temp[i];
        end
    endrule

    rule c_column4(counter == 16);
        Vector#(4, Bit#(32)) temp <- systolic_unit.get_result;
        for(Integer i = 0; i < 4; i = i+1)
        begin
            c_matrix_top[4][i] <= temp[i];
        end
    endrule

    rule c_column3(counter == 18);
        Vector#(4, Bit#(32)) temp <- systolic_unit.get_result;
        for(Integer i = 0; i < 4; i = i+1)
        begin
            c_matrix_top[3][i] <= temp[i];
        end
    endrule    

    rule c_column2(counter == 20);
        Vector#(4, Bit#(32)) temp <- systolic_unit.get_result;
        for(Integer i = 0; i < 4; i = i+1)
        begin
            c_matrix_top[2][i] <= temp[i];
        end
    endrule 
    
    rule c_column1(counter == 22);
        Vector#(4, Bit#(32)) temp <- systolic_unit.get_result;
        for(Integer i = 0; i < 4; i = i+1)
        begin
            c_matrix_top[1][i] <= temp[i];
        end
    endrule

    rule c_column0(counter == 24);
        Vector#(4, Bit#(32)) temp <- systolic_unit.get_result;
        for(Integer i = 0; i < 4; i = i+1)
        begin
            c_matrix_top[0][i] <= temp[i];
        end
    endrule

    rule count_up;
        counter <= counter+1;
    endrule

    method Action set_A_matrix_in (Vector#(4, Vector#(4, Bit#(16))) a_matrix_in);
        a_matrix_top[6][0] <= a_matrix_in[0][0];
        a_matrix_top[5][0] <= a_matrix_in[1][0];
        a_matrix_top[4][0] <= a_matrix_in[2][0];
        a_matrix_top[3][0] <= a_matrix_in[3][0];
        a_matrix_top[2][0] <= 0;
        a_matrix_top[1][0] <= 0;
        a_matrix_top[0][0] <= 0;

        a_matrix_top[6][1] <= 0;
        a_matrix_top[5][1] <= a_matrix_in[0][1];
        a_matrix_top[4][1] <= a_matrix_in[1][1];
        a_matrix_top[3][1] <= a_matrix_in[2][1];
        a_matrix_top[2][1] <= a_matrix_in[3][1];
        a_matrix_top[1][1] <= 0;
        a_matrix_top[0][1] <= 0;

        a_matrix_top[6][2] <= 0;
        a_matrix_top[5][2] <= 0;
        a_matrix_top[4][2] <= a_matrix_in[0][2];
        a_matrix_top[3][2] <= a_matrix_in[1][2];
        a_matrix_top[2][2] <= a_matrix_in[2][2];
        a_matrix_top[1][2] <= a_matrix_in[3][2];
        a_matrix_top[0][2] <= 0;

        a_matrix_top[6][3] <= 0;
        a_matrix_top[5][3] <= 0;
        a_matrix_top[4][3] <= 0;
        a_matrix_top[3][3] <= a_matrix_in[0][3];
        a_matrix_top[2][3] <= a_matrix_in[1][3];
        a_matrix_top[1][3] <= a_matrix_in[2][3];
        a_matrix_top[0][3] <= a_matrix_in[3][3];
    endmethod

    method Action set_B_matrix_in (Vector#(4, Vector#(4, Bit#(16))) b_matrix_in);
        for(Integer i = 0; i < 4; i = i+1)
        begin
            for(Integer j = 0; j < 4; j = j+1)
            begin
                b_matrix_top[i][j] <= b_matrix_in[i][j];
            end
        end
    endmethod

    method Action set_s1_or_s2_top (Bit#(1) s1_or_s2_in);
        s1_or_s2_systolic <= s1_or_s2_in;
    endmethod

    method Vector#(4, Vector#(4, Bit#(32))) get_matrix_mul_result;
        Vector#(4, Vector#(4, Bit#(32))) filtered_ans = replicate(replicate(0));

        filtered_ans[0][0] = c_matrix_top[6][0];
        filtered_ans[0][1] = c_matrix_top[5][1];
        filtered_ans[0][2] = c_matrix_top[4][2];
        filtered_ans[0][3] = c_matrix_top[3][3];

        filtered_ans[1][0] = c_matrix_top[5][0];
        filtered_ans[1][1] = c_matrix_top[4][1];
        filtered_ans[1][2] = c_matrix_top[3][2];
        filtered_ans[1][3] = c_matrix_top[2][3];

        filtered_ans[2][0] = c_matrix_top[4][0];
        filtered_ans[2][1] = c_matrix_top[3][1];
        filtered_ans[2][2] = c_matrix_top[2][2];
        filtered_ans[2][3] = c_matrix_top[1][3];

        filtered_ans[3][0] = c_matrix_top[3][0];
        filtered_ans[3][1] = c_matrix_top[2][1];
        filtered_ans[3][2] = c_matrix_top[1][2];
        filtered_ans[3][3] = c_matrix_top[0][3];

        return filtered_ans;        
    endmethod

endmodule


//(* synthesize *)
module mkTb ( );
    let ifc <- mkTopSystolic;
    Reg#(Bit#(32)) i <- mkReg(0);

    //Vector#(4, Vector#(4, Bit#(16))) b = unpack({
    //    16'd1, 16'd2, 16'd3, 16'd4,    // Row 0
    //    16'd5, 16'd6, 16'd7, 16'd8,    // Row 1
    //    16'd9, 16'd10, 16'd11, 16'd12, // Row 2
    //    16'd13, 16'd14, 16'd15, 16'd16 // Row 3
    //});

    Vector#(4, Vector#(4, Bit#(16))) a = unpack({
        16'd0, 16'd0, 16'd0, 16'd0,    // Row 0
        16'd0, 16'd8, 16'd7, 16'd-16,    // Row 1
        16'd0, 16'd13, 16'd4, 16'd0, // Row 2
        16'd0, 16'd-9, 16'd7, 16'd2 // Row 3
    });

    Vector#(4, Vector#(4, Bit#(16))) b = unpack({
        16'd0, 16'd0, 16'd0, 16'd0,    // Row 0
        16'd0, 16'd7, 16'd-11, 16'd4,    // Row 1
        16'd0, 16'd6, 16'd0, 16'd-1, // Row 2
        16'd0, 16'd1, 16'd13, 16'd7 // Row 3
    });

    rule stage1(i == 0);
        $display ("---------------- Cycle %d start ----------------------", i);
        ifc.set_A_matrix_in (a);
        for(Integer k = 0; k < 4; k = k+1)
        begin
            for(Integer j = 0; j < 4; j = j+1)
            begin
                $display ("b[%d][%d]: %16d", k, j, b[k][j]);
            end
        end
        ifc.set_B_matrix_in (b);
        ifc.set_s1_or_s2_top (1'b1);
    endrule

    rule stage2(i == 25);
        $display ("---------------- Cycle %d start ----------------------", i);
        Vector#(4, Vector#(4, Bit#(32))) ans = ifc.get_matrix_mul_result;

        for(Integer k = 0; k < 4; k = k+1)
        begin
            for(Integer j = 0; j < 4; j = j+1)
            begin
                $display ("The answer is: %d", ans[k][j]);
            end
        end
        $finish (0);
    endrule

    rule counter;
        i <= i+1;
    endrule

endmodule: mkTb

endpackage

//*************************************************************************
// END OF FILE
//*************************************************************************