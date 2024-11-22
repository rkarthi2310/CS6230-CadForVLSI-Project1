#*************************************************************************
# CS6230 CAD FOR VLSI PROJECT 1: MULTIPLY-ACCUMULATE (MAC) UNIT 
#
# FILE: model_mac.py
#
# AUTHORS: Karthikeyan R CS23S039
#          Arun Prabakar CS23D012
#
#*************************************************************************

import cocotb
from cocotb_coverage.coverage import *
import tensorflow as tf
import numpy as np
from test_patterns import *

coverage_test_pattern_func = [generate_walking_ones,
                     generate_walking_zeros,
                     generate_alternating_ones,
                     generate_alternating_zeros,
                     generate_powers_of_two_minus_one,
                     generate_sliding_zeros,
                     generate_sliding_ones,
                     generate_random_binary
                     ]

coverage_sign_bits = ['1', '0']

coverage_exponent_exception = ['11111111', '00000000']

COV_EXPONENT_SIZE = 8
COV_MANTISSA_SIZE_BF16 = 7
COV_MANTISSA_SIZE_FP32 = 23

cov_A_val = []
cov_B_val = []
cov_C_val = []

# Generate test patterns
for sign in coverage_sign_bits:
    for exponent_pattern_index in range(len(coverage_test_pattern_func)):
        exponent_pattern_list = coverage_test_pattern_func[exponent_pattern_index](COV_EXPONENT_SIZE)
        for exponent_pattern in exponent_pattern_list:
            for mantissa_pattern_index in range(len(coverage_test_pattern_func)):
                mantissa_pattern_list = coverage_test_pattern_func[mantissa_pattern_index](COV_MANTISSA_SIZE_BF16)
                for mantissa_pattern in mantissa_pattern_list:
                    test_pattern_instance = sign+exponent_pattern+mantissa_pattern
                    cov_A_val.append(test_pattern_instance)
                    cov_B_val.append(test_pattern_instance)
            for mantissa_pattern_index in range(len(coverage_test_pattern_func)):
                mantissa_pattern_list = coverage_test_pattern_func[mantissa_pattern_index](COV_MANTISSA_SIZE_FP32)
                for mantissa_pattern in mantissa_pattern_list:
                    test_pattern_instance = sign+exponent_pattern+mantissa_pattern
                    cov_C_val.append(test_pattern_instance)

COV_MULTIPLICAND_SIZE = 16
COV_ADDEND_SIZE = 32

# Generate test patterns
for test_pattern_index in range(len(coverage_test_pattern_func)):
    multplicand_pattern_list = coverage_test_pattern_func[test_pattern_index](COV_MULTIPLICAND_SIZE)
    for multplicand_pattern in multplicand_pattern_list:
        cov_A_val.append(multplicand_pattern)
        cov_B_val.append(multplicand_pattern)
    multplicand_pattern_list = coverage_test_pattern_func[test_pattern_index](COV_ADDEND_SIZE)
    for multplicand_pattern in multplicand_pattern_list:
        cov_C_val.append(multplicand_pattern)

# Generate random testcases
for i in range(30):
    cov_A_val.append(generate_random_binary(16))
    cov_B_val.append(generate_random_binary(16))
    cov_C_val.append(generate_random_binary(32))


mac_coverage = coverage_section(
    CoverPoint('top.set_inputs_a_in', vname='set_inputs_a_in', bins = list(range(32))), #cov_A_val),
    CoverPoint('top.set_inputs_b_in', vname='set_inputs_b_in', bins = list(range(32))), #cov_B_val),
    CoverPoint('top.set_inputs_c_in', vname='set_inputs_c_in', bins = list(range(32))), #cov_C_val),
    CoverPoint('top.set_inputs_s1_or_s2_in', vname='set_inputs_s1_or_s2_in', bins = list(range(2))),
    CoverCross('top.cross_cover', items = ['top.set_inputs_a_in','top.set_inputs_b_in','top.set_inputs_c_in','top.set_inputs_s1_or_s2_in'])
)

def binary_string_to_bfloat16(binary_str):
    """
    Convert a 16-bit binary string to bfloat16.
    The binary string should be in the format '1111111111111111' (16 characters).
    """
    # Convert binary string to integer
    int_val = int(binary_str, 2)
    
    # Create a 16-bit unsigned integer tensor
    uint16_tensor = tf.constant([int_val], dtype=tf.uint16)
    
    # Reinterpret the bits as bfloat16
    return tf.bitcast(uint16_tensor, tf.bfloat16)[0]

def binary_string_to_fp32(binary_str):
    """
    Convert a 16-bit binary string to bfloat16.
    The binary string should be in the format '1111111111111111' (16 characters).
    """
    # Convert binary string to integer
    int_val = int(binary_str, 2)
    
    # Create a 16-bit unsigned integer array with our value
    uint32_array = np.array([int_val], dtype=np.uint32)
    
    # Reinterpret the bits as bfloat16
    return uint32_array.view(np.float32)[0]

def bfloat16_to_binary_string(bfloat16_val):
    """Convert a bfloat16 value back to its binary string representation"""
    # Convert to uint16 and get the integer value
    uint16_val = tf.bitcast(tf.expand_dims(bfloat16_val, 0), tf.uint16)
    int_val = uint16_val.numpy()[0]
    # Convert to 16-bit binary string
    return format(int_val, '016b')

def fp32_to_binary_string(fp32_val):
    """Convert a bfloat16 value back to its binary string representation"""
    uint32_val = fp32_val.view(np.uint32)
    return format(uint32_val, '032b')

def int_to_twos_complement(num, n_bits):
    """
    Convert a signed integer to its n-bit two's complement binary 
    representation.
    """
    if n_bits <= 0:
        raise ValueError("Number of bits must be positive")
        
    # Calculate the range of values that can be represented with n_bits
    min_value = -(2 ** (n_bits - 1))
    max_value = 2 ** (n_bits - 1) - 1
    
    if not min_value <= num <= max_value:
        raise ValueError(
            f"Number {num} cannot be represented in {n_bits} bits. "
            f"Range is [{min_value}, {max_value}]"
        )
    
    # For positive numbers and zero
    if num >= 0:
        # Convert to binary and remove '0b' prefix
        binary = format(num, f'0{n_bits}b')
    
    # For negative numbers
    else:
        abs_num = abs(num)
        binary = format(abs_num, f'0{n_bits}b')
        flipped = ''.join('1' if bit == '0' else '0' for bit in binary)
        twos_complement = format((int(flipped, 2) + 1) & ((1 << n_bits) - 1), f'0{n_bits}b')
        binary = twos_complement
    
    return binary

def multiply_bfloat16(x_binary_string, y_binary_string):
    
    # Convert binary strings to bfloat16 tensors
    x = tf.stack([binary_string_to_bfloat16(b) for b in x_binary_string])
    y = tf.stack([binary_string_to_bfloat16(b) for b in y_binary_string])

    # Multiplication operation
    multiplication = x * y
        
    multiplication_binary = [bfloat16_to_binary_string(val) for val in multiplication]

    return multiplication_binary

def add_fp32(x_binary_string, y_binary_string):
    
    # Convert binary strings to fp32 arrays
    x = np.array([binary_string_to_fp32(b) for b in x_binary_string])
    y = np.array([binary_string_to_fp32(b) for b in y_binary_string])
    
    # Addition operation
    addition = x + y
        
    addition_binary = [fp32_to_binary_string(val) for val in addition]

    return addition_binary

def mac_fp32(a, b, c):
    ab_binary_strings = multiply_bfloat16(a, b)

    for i in range(len(ab_binary_strings)):
        ab_binary_strings[i] = (ab_binary_strings[i] + 16*'0')

    #print('ab model: ', ab_binary_strings)
    mac_binary_strings = add_fp32(ab_binary_strings, c)
    #print('mac_model: ', mac_binary_strings)

    ab_exponents = [ab[1:9] for ab in ab_binary_strings]

    return [mac_binary_strings, ab_exponents]

def mac_int8(a, b, c):

    a_num = [int(element, 2) for element in a]
    b_num = [int(element, 2) for element in b]
    c_num = [int(element, 2) for element in c]

    # Convert binary strings to numpy arrays
    a_np = np.array(a_num, dtype=np.int8)
    b_np = np.array(b_num, dtype=np.int8)
    c_np = np.array(c_num, dtype=np.int32)
    
    # Multiplication operation
    ab_np = np.array(a_np, dtype=np.int16) * np.array(b_np, dtype=np.int16)

    mac = ab_np + c_np

    mac = [int_to_twos_complement(element, 32) for element in mac]

    return [mac, []]

def multiply_4x4_matrices_bf16(matrix1, matrix2):
    """
    Multiply two 4x4 matrices.
    
    Args:
        matrix1: List of 4 lists, each containing 4 numbers. 
                 Each  number is a list of 1 element.
        matrix2: List of 4 lists, each containing 4 numbers.
                 Each  number is a list of 1 element.
        
    Returns:
        result: List of 4 lists, each containing 4 numbers
    """
    # Initialize result matrix with zeros
    result = [[['0'*32] for _ in range(4)] for _ in range(4)]
    
    # Perform matrix multiplication
    for i in range(4):
        for j in range(4):
            for k in range(4):
                temp1 = multiply_bfloat16(matrix1[i][k], matrix2[k][j])
                for i in range(len(temp1)):
                    temp1[i] = (temp1[i] + 16*'0')
                temp1_exponent = [ab[1:9] for ab in temp1]
                temp2 = add_fp32(temp1, result[i][j])
                if(temp2[0][1:9] in coverage_exponent_exception or 
                   temp1_exponent in coverage_exponent_exception):
                    return [result, 0]
                result[i][j] = temp2
                
    return [result, 1]

def multiply_4x4_matrices_int8(matrix1, matrix2):
    """
    Multiply two 4x4 matrices.
    
    Args:
        matrix1: List of 4 lists, each containing 4 numbers. 
                 Each  number is a list of 1 element.
        matrix2: List of 4 lists, each containing 4 numbers.
                 Each  number is a list of 1 element.
        
    Returns:
        result: List of 4 lists, each containing 4 numbers
    """
    # Initialize result matrix with zeros
    result = [[['0'*32] for _ in range(4)] for _ in range(4)]
    
    # Perform matrix multiplication
    for i in range(4):
        for j in range(4):
            for k in range(4):
                temp_a = [int(element, 2) for element in matrix1[i][k]]
                temp_b = [int(element, 2) for element in matrix2[k][j]]

                temp_a_np = np.array(temp_a, dtype=np.int8)
                temp_b_np = np.array(temp_b, dtype=np.int8)
                temp_c_np = np.array(result[i][j], dtype=np.int32)
                temp1 = np.array(temp_a_np, dtype=np.int16) * np.array(temp_b_np, dtype=np.int16)
                temp2 = temp1 + temp_c_np
                temp2 = [int_to_twos_complement(element, 32) for element in temp2]
                result[i][j] = temp2
                
    return [result, 1]

#*************************************************************************
# END OF FILE
#*************************************************************************