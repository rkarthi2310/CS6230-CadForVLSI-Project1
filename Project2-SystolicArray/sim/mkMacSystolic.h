/*
 * Generated by Bluespec Compiler, version 2021.12.1 (build fd501401)
 * 
 * On Sun Nov 17 07:27:54 IST 2024
 * 
 */

/* Generation options: */
#ifndef __mkMacSystolic_h__
#define __mkMacSystolic_h__

#include "bluesim_types.h"
#include "bs_module.h"
#include "bluesim_primitives.h"
#include "bs_vcd.h"


/* Class declaration for the mkMacSystolic module */
class MOD_mkMacSystolic : public Module {
 
 /* Clock handles */
 private:
  tClock __clk_handle_0;
 
 /* Clock gate handles */
 public:
  tUInt8 *clk_gate[0];
 
 /* Instantiation parameters */
 public:
 
 /* Module state */
 public:
  MOD_Fifo<tUInt32> INST_a_1;
  MOD_Fifo<tUInt32> INST_a_2;
  MOD_Wire<tUInt32> INST_a_out;
  MOD_Fifo<tUInt32> INST_b_1;
  MOD_Wire<tUInt32> INST_b_out;
  MOD_Fifo<tUInt32> INST_c_1;
  MOD_Fifo<tUInt32> INST_c_2;
  MOD_Reg<tUInt32> INST_counter;
  MOD_Fifo<tUInt32> INST_mac_intermediate_AB;
  MOD_Wire<tUInt32> INST_result;
  MOD_Fifo<tUInt8> INST_s1_or_s2_1;
  MOD_Fifo<tUInt8> INST_s1_or_s2_2;
  MOD_Wire<tUInt8> INST_s1_or_s2_out;
  MOD_Reg<tUInt8> INST_transfer_b;
 
 /* Constructor */
 public:
  MOD_mkMacSystolic(tSimStateHdl simHdl, char const *name, Module *parent);
 
 /* Symbol init methods */
 private:
  void init_symbols_0();
 
 /* Reset signal definitions */
 private:
  tUInt8 PORT_RST_N;
 
 /* Port definitions */
 public:
 
 /* Publicly accessible definitions */
 public:
 
 /* Local definitions */
 private:
  tUInt32 DEF_new_value__h120287;
 
 /* Rules */
 public:
  void RL_count_up();
  void RL_perform_mac_stage1();
  void RL_perform_mac_stage2();
  void RL_send_b();
 
 /* Methods */
 public:
  void METH_set_state(tUInt8 ARG_set_state_transfer_b_state);
  tUInt8 METH_RDY_set_state();
  void METH_set_a(tUInt32 ARG_set_a_a_in);
  tUInt8 METH_RDY_set_a();
  void METH_set_b(tUInt32 ARG_set_b_b_in);
  tUInt8 METH_RDY_set_b();
  void METH_set_c(tUInt32 ARG_set_c_c_in);
  tUInt8 METH_RDY_set_c();
  void METH_set_s1_or_s2(tUInt8 ARG_set_s1_or_s2_s1_or_s2_in);
  tUInt8 METH_RDY_set_s1_or_s2();
  tUInt32 METH_get_result();
  tUInt8 METH_RDY_get_result();
  tUInt32 METH_get_a();
  tUInt8 METH_RDY_get_a();
  tUInt32 METH_get_b();
  tUInt8 METH_RDY_get_b();
  tUInt8 METH_get_s1_or_s2();
  tUInt8 METH_RDY_get_s1_or_s2();
 
 /* Reset routines */
 public:
  void reset_RST_N(tUInt8 ARG_rst_in);
 
 /* Static handles to reset routines */
 public:
 
 /* Pointers to reset fns in parent module for asserting output resets */
 private:
 
 /* Functions for the parent module to register its reset fns */
 public:
 
 /* Functions to set the elaborated clock id */
 public:
  void set_clk_0(char const *s);
 
 /* State dumping routine */
 public:
  void dump_state(unsigned int indent);
 
 /* VCD dumping routines */
 public:
  unsigned int dump_VCD_defs(unsigned int levels);
  void dump_VCD(tVCDDumpType dt, unsigned int levels, MOD_mkMacSystolic &backing);
  void vcd_defs(tVCDDumpType dt, MOD_mkMacSystolic &backing);
  void vcd_prims(tVCDDumpType dt, MOD_mkMacSystolic &backing);
};

#endif /* ifndef __mkMacSystolic_h__ */
