#*************************************************************************
# CS6230 CAD FOR VLSI PROJECT 1: MULTIPLY-ACCUMULATE (MAC) UNIT 
#
# FILE: test_mac.py
#
# AUTHORS: Karthikeyan R CS23S039
#          Arun Prabakar CS23D012
#
#*************************************************************************

import os
import random
from pathlib import Path
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
from cocotb_coverage.coverage import *
from test_patterns import *
from model_mac import *

test_pattern_func = [generate_walking_ones,
                     #generate_walking_zeros,
                     #generate_alternating_ones,
                     #generate_alternating_zeros,
                     #generate_powers_of_two_minus_one,
                     #generate_sliding_zeros,
                     #generate_sliding_ones,
                     #generate_random_binary
                     ]

sign_bits = ['1', '0']

exponent_exception = ['11111111', '00000000']

@cocotb.test()
async def test_mac(dut):
    """Test to check MAC"""
    for is_int in range(2):
        if(is_int == 1):
            a_path = "/home/shakti/mac/verification_unpipelined/test_cases/int8MAC/A_binary.txt"
            b_path = "/home/shakti/mac/verification_unpipelined/test_cases/int8MAC/B_binary.txt"
            c_path = "/home/shakti/mac/verification_unpipelined/test_cases/int8MAC/C_binary.txt"
            mac_result_path = "/home/shakti/mac/verification_unpipelined/test_cases/int8MAC/MAC_binary.txt"
            model_func = mac_int8
        else:
            a_path = "/home/shakti/mac/verification_unpipelined/test_cases/bf16MAC/A_binary.txt"
            b_path = "/home/shakti/mac/verification_unpipelined/test_cases/bf16MAC/B_binary.txt"
            c_path = "/home/shakti/mac/verification_unpipelined/test_cases/bf16MAC/C_binary.txt"
            mac_result_path = "/home/shakti/mac/verification_unpipelined/test_cases/bf16MAC/MAC_binary.txt"
            model_func = mac_fp32

        f = open(a_path, 'r')
        A = f.read().splitlines()
        f.close()

        f = open(b_path, 'r')
        B = f.read().splitlines()
        f.close()

        f = open(c_path, 'r')
        C = f.read().splitlines()
        f.close()
        
        f = open(mac_result_path, 'r')
        MAC = f.read().splitlines()
        f.close()

        A_tp = []
        B_tp = []
        C_tp = []

        if (is_int == 0):
            EXPONENT_SIZE = 8
            MANTISSA_SIZE_BF16 = 7
            MANTISSA_SIZE_FP32 = 23

            # Generate test patterns
            for sign in sign_bits:
                for exponent_pattern_index in range(len(test_pattern_func)):
                    exponent_pattern_list = test_pattern_func[exponent_pattern_index](EXPONENT_SIZE)
                    for exponent_pattern in exponent_pattern_list:
                        for mantissa_pattern_index in range(len(test_pattern_func)):
                            mantissa_pattern_list = test_pattern_func[mantissa_pattern_index](MANTISSA_SIZE_BF16)
                            for mantissa_pattern in mantissa_pattern_list:
                                test_pattern_instance = sign+exponent_pattern+mantissa_pattern
                                A_tp.append(test_pattern_instance)
                                B_tp.append(test_pattern_instance)
                        for mantissa_pattern_index in range(len(test_pattern_func)):
                            mantissa_pattern_list = test_pattern_func[mantissa_pattern_index](MANTISSA_SIZE_FP32)
                            for mantissa_pattern in mantissa_pattern_list:
                                test_pattern_instance = sign+exponent_pattern+mantissa_pattern
                                C_tp.append(test_pattern_instance)
        else:
            MULTIPLICAND_SIZE = 16
            ADDEND_SIZE = 32

            # Generate test patterns
            for test_pattern_index in range(len(test_pattern_func)):
                multplicand_pattern_list = test_pattern_func[test_pattern_index](MULTIPLICAND_SIZE)
                for multplicand_pattern in multplicand_pattern_list:
                    A_tp.append(multplicand_pattern)
                    B_tp.append(multplicand_pattern)
                multplicand_pattern_list = test_pattern_func[test_pattern_index](ADDEND_SIZE)
                for multplicand_pattern in multplicand_pattern_list:
                    C_tp.append(multplicand_pattern)
        
        A_rand = []
        B_rand = []
        C_rand = []

        if (is_int == 0):
            MULTIPLICAND_SIZE = 16
            ADDEND_SIZE = 32

            # Generate random testcases
            for i in range(30):
                A_rand.append(generate_random_binary(16))
                B_rand.append(generate_random_binary(16))
                C_rand.append(generate_random_binary(32))
        else:
            MULTIPLICAND_SIZE = 8
            ADDEND_SIZE = 32

            # Generate random testcases
            for i in range(30):
                A_rand.append(generate_random_binary(16))
                B_rand.append(generate_random_binary(16))
                C_rand.append(generate_random_binary(32))

        pipelined = 0

        clock = Clock(dut.CLK, 10, units="us")  # Create a 10us period clock on port clk
        # Start the clock. Start it low to avoid issues on the first RisingEdge
        cocotb.start_soon(clock.start(start_high=False))

        if(pipelined == 0):

            # Test using testcases

            dut.EN_mac.value = 0
            dut.RST_N.value = 0
            await RisingEdge(dut.CLK)
            dut.RST_N.value = 1
            dut.EN_mac.value = 1
            dut._log.info('Starting test: Using Testcases')

            for i in range(len(A)):
                dut.mac_s1_or_s2.value = int(str(is_int), 2)
                dut.mac_a.value = int(A[i], 2)
                dut.mac_b.value = int(B[i], 2)
                dut.mac_c.value = int(C[i], 2)

                await RisingEdge(dut.CLK)

                mac_output = int(dut.mac.value)
                dut._log.info(f'output {bin(mac_output)}')
                
                mac_expected_result = int(MAC[i], 2)

                if(is_int == 1): assert mac_expected_result == mac_output, f'Counter Output Mismatch, Expected = {bin(mac_expected_result)} DUT = {bin(mac_output)}'
                else: assert abs(mac_expected_result - mac_output) < 4, f'Counter Output Mismatch, Expected = {bin(mac_expected_result)} DUT = {bin(mac_output)}'

            # Test using test patterns
            
            dut.EN_mac.value = 0
            dut.RST_N.value = 0
            await RisingEdge(dut.CLK)
            dut.RST_N.value = 1
            dut.EN_mac.value = 1
            dut._log.info('Starting test: Using Test Patterns')

            for i in range(len(A_tp)):
                if(is_int == 0 and A_tp[i][1:9] in exponent_exception):
                    continue
                for j in range(len(B_tp)):
                    if(is_int == 0 and B_tp[j][1:9] in exponent_exception):
                        continue
                    for k in range(len(C_tp)):
                        if(is_int == 0 and C_tp[k][1:9] in exponent_exception):
                            continue
                        A_model = [A_tp[i]]
                        B_model = [B_tp[j]]
                        C_model = [C_tp[k]]
                        mac_expected_result = model_func(A_model, B_model, C_model)
                        if(is_int == 0 and 
                        (mac_expected_result[0][0][1:9] in exponent_exception or mac_expected_result[1][0] in exponent_exception)):
                            continue
                        mac_expected_result = int(mac_expected_result[0][0], 2)

                        dut.mac_s1_or_s2.value = int(str(is_int), 2)
                        dut.mac_a.value = int(A_tp[i], 2)
                        dut.mac_b.value = int(B_tp[j], 2)
                        dut.mac_c.value = int(C_tp[k], 2)

                        await RisingEdge(dut.CLK)

                        mac_output = int(dut.mac.value)
                        dut._log.info(f'output {bin(mac_output)}')

                        if(is_int == 1): assert mac_expected_result == mac_output, f'Counter Output Mismatch, Expected = {bin(mac_expected_result)} DUT = {bin(mac_output)}'
                        else: assert abs(mac_expected_result - mac_output) < 4, f'Counter Output Mismatch, Expected = {bin(mac_expected_result)} DUT = {bin(mac_output)}'
            
            # Test using random testcases
            
            dut.EN_mac.value = 0
            dut.RST_N.value = 0
            await RisingEdge(dut.CLK)
            dut.RST_N.value = 1
            dut.EN_mac.value = 1
            dut._log.info('Starting test: Using Random Test Cases')

            for i in range(len(A_tp)):
                if(is_int == 0 and A_tp[i][1:9] in exponent_exception):
                    continue
                for j in range(len(B_tp)):
                    if(is_int == 0 and B_tp[j][1:9] in exponent_exception):
                        continue
                    for k in range(len(C_tp)):
                        if(is_int == 0 and C_tp[k][1:9] in exponent_exception):
                            continue
                        A_model = [A_rand[i]]
                        B_model = [B_rand[j]]
                        C_model = [C_rand[k]]
                        mac_expected_result = model_func(A_model, B_model, C_model)
                        if(is_int == 0 and 
                        (mac_expected_result[0][0][1:9] in exponent_exception or mac_expected_result[1][0] in exponent_exception)):
                            continue
                        mac_expected_result = int(mac_expected_result[0][0], 2)

                        dut.mac_s1_or_s2.value = int(str(is_int), 2)
                        dut.mac_a.value = int(A_rand[i], 2)
                        dut.mac_b.value = int(B_rand[j], 2)
                        dut.mac_c.value = int(C_rand[k], 2)

                        await RisingEdge(dut.CLK)

                        mac_output = int(dut.mac.value)
                        dut._log.info(f'output {bin(mac_output)}')

                        if(is_int == 1): assert mac_expected_result == mac_output, f'Counter Output Mismatch, Expected = {bin(mac_expected_result)} DUT = {bin(mac_output)}'
                        else: assert abs(mac_expected_result - mac_output) < 4, f'Counter Output Mismatch, Expected = {bin(mac_expected_result)} DUT = {bin(mac_output)}'


        else:

            # Test using testcases

            dut.EN_set_inputs.value = 0
            dut.RST_N.value = 0
            await RisingEdge(dut.CLK)
            dut.RST_N.value = 1
            dut.EN_set_inputs.value = 1
            dut._log.info('Starting test: Using Test cases')

            dut.set_inputs_s1_or_s2_in.value = int(str(is_int), 2)
            dut.set_inputs_a_in.value = int(A[0], 2)
            dut.set_inputs_b_in.value = int(B[0], 2)
            dut.set_inputs_c_in.value = int(C[0], 2)

            await RisingEdge(dut.CLK)
            mac_output = int(dut.get_result.value)
            dut._log.info(f'Cycle 0 output {mac_output}')

            dut.set_inputs_s1_or_s2_in.value = int(str(is_int), 2)
            dut.set_inputs_a_in.value = int(A[1], 2)
            dut.set_inputs_b_in.value = int(B[1], 2)
            dut.set_inputs_c_in.value = int(C[1], 2)    

            await RisingEdge(dut.CLK)
            mac_output = int(dut.get_result.value)
            dut._log.info(f'Cycle 1 output {mac_output}')

            for i in range(len(A)):
            
                if(i < (len(A)-2)):
                    dut.set_inputs_s1_or_s2_in.value = int(str(is_int), 2)
                    dut.set_inputs_a_in.value = int(A[i+2], 2)
                    dut.set_inputs_b_in.value = int(B[i+2], 2)
                    dut.set_inputs_c_in.value = int(C[i+2], 2)

                await RisingEdge(dut.CLK)

                mac_output = int(dut.get_result.value)
                dut._log.info(f'output {mac_output}')
                
                mac_expected_result = int(MAC[i], 2)

                if(is_int == 1): assert mac_expected_result == mac_output, f'Counter Output Mismatch, Expected = {bin(mac_expected_result)} DUT = {bin(mac_output)}'
                else: assert abs(mac_expected_result - mac_output) < 4, f'Counter Output Mismatch, Expected = {bin(mac_expected_result)} DUT = {bin(mac_output)}'

            # Test using Test Patterns
            
            dut.EN_set_inputs.value = 0
            dut.RST_N.value = 0
            await RisingEdge(dut.CLK)
            dut.RST_N.value = 1
            dut.EN_set_inputs.value = 1
            dut._log.info('Starting test: Using Test Patterns')

            mac_expected_result_list = []
            values_loaded = 0
            
            for i in range(len(A_tp)):
                if(is_int == 0 and A_tp[i][1:9] in exponent_exception):
                    continue
                for j in range(len(B_tp)):
                    if(is_int == 0 and B_tp[j][1:9] in exponent_exception):
                        continue
                    for k in range(len(C_tp)):
                        if(is_int == 0 and C_tp[k][1:9] in exponent_exception):
                            continue
                        A_model = [A_tp[i]]
                        B_model = [B_tp[j]]
                        C_model = [C_tp[k]]
                        mac_expected_result = model_func(A_model, B_model, C_model)
                        if(is_int == 0 and 
                        (mac_expected_result[0][0][1:9] in exponent_exception or mac_expected_result[1][0] in exponent_exception)):
                            continue
                        mac_expected_result = int(mac_expected_result[0][0], 2)
                        mac_expected_result_list.append(mac_expected_result)

                        dut.set_inputs_s1_or_s2_in.value = int(str(is_int), 2)
                        dut.set_inputs_a_in.value = int(A_tp[i], 2)
                        dut.set_inputs_b_in.value = int(B_tp[j], 2)
                        dut.set_inputs_c_in.value = int(C_tp[k], 2)
                        values_loaded += 1

                        await RisingEdge(dut.CLK)

                        mac_output = int(dut.get_result.value)
                        dut._log.info(f'output {mac_output}')

                        if(values_loaded > 2): # Wait 2 cycles because 2-stage pipeline 
                            mac_expected_result_value = mac_expected_result_list[0]
                            if(is_int == 1): assert mac_expected_result_value == mac_output, f'Counter Output Mismatch, Expected = {bin(mac_expected_result)} DUT = {bin(mac_output)}'
                            else: assert abs(mac_expected_result_value - mac_output) < 4, f'Counter Output Mismatch, Expected = {bin(mac_expected_result)} DUT = {bin(mac_output)}'
                            mac_expected_result_list.pop(0)

            # Test using Random Test Cases
            
            dut.EN_set_inputs.value = 0
            dut.RST_N.value = 0
            await RisingEdge(dut.CLK)
            dut.RST_N.value = 1
            dut.EN_set_inputs.value = 1
            dut._log.info('Starting test: Using Random Test Cases')

            mac_expected_result_list = []
            values_loaded = 0
            
            for i in range(len(A_tp)):
                if(is_int == 0 and A_tp[i][1:9] in exponent_exception):
                    continue
                for j in range(len(B_tp)):
                    if(is_int == 0 and B_tp[j][1:9] in exponent_exception):
                        continue
                    for k in range(len(C_tp)):
                        if(is_int == 0 and C_tp[k][1:9] in exponent_exception):
                            continue
                        A_model = [A_rand[i]]
                        B_model = [B_rand[j]]
                        C_model = [C_rand[k]]
                        mac_expected_result = model_func(A_model, B_model, C_model)
                        if(is_int == 0 and 
                        (mac_expected_result[0][0][1:9] in exponent_exception or mac_expected_result[1][0] in exponent_exception)):
                            continue
                        mac_expected_result = int(mac_expected_result[0][0], 2)
                        mac_expected_result_list.append(mac_expected_result)

                        dut.set_inputs_s1_or_s2_in.value = int(str(is_int), 2)
                        dut.set_inputs_a_in.value = int(A_rand[i], 2)
                        dut.set_inputs_b_in.value = int(B_rand[j], 2)
                        dut.set_inputs_c_in.value = int(C_rand[k], 2)
                        values_loaded += 1

                        await RisingEdge(dut.CLK)

                        mac_output = int(dut.get_result.value)
                        dut._log.info(f'output {mac_output}')

                        if(values_loaded > 2): # Wait 2 cycles because 2-stage pipeline 
                            mac_expected_result_value = mac_expected_result_list[0]
                            if(is_int == 1): assert mac_expected_result_value == mac_output, f'Counter Output Mismatch, Expected = {bin(mac_expected_result)} DUT = {bin(mac_output)}'
                            else: assert abs(mac_expected_result_value - mac_output) < 4, f'Counter Output Mismatch, Expected = {bin(mac_expected_result)} DUT = {bin(mac_output)}'
                            mac_expected_result_list.pop(0)

    coverage_db.export_to_yaml(filename="coverage_mac.yml")

#*************************************************************************
# END OF FILE
#*************************************************************************