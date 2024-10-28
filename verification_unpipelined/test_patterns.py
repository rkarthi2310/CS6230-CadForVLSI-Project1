#*************************************************************************
# CS6230 CAD FOR VLSI PROJECT 1: MULTIPLY-ACCUMULATE (MAC) UNIT 
#
# FILE: test_patterns.py
#
# AUTHORS: Karthikeyan R CS23S039
#          Arun Prabakar CS23D012
#
#*************************************************************************

import random

def generate_walking_ones(n):
    """
    Generate n-bit walking ones pattern.
    Example for n=4: 0001, 0010, 0100, 1000
    """
    patterns = []
    for i in range(n):
        pattern = 1 << i
        patterns.append(format(pattern, f'0{n}b'))
    patterns.reverse()
    return patterns

def generate_walking_zeros(n):
    """
    Generate n-bit walking zeros pattern.
    Example for n=4: 1110, 1101, 1011, 0111
    """
    patterns = []
    for i in range(n):
        # Create all 1s then clear one bit
        pattern = (1 << n) - 1  # all ones
        pattern &= ~(1 << i)    # clear bit at position i
        patterns.append(format(pattern, f'0{n}b'))
    patterns.reverse()
    return patterns

def generate_alternating_zeros(n):
    """
    Generate n-bit alternating zeros pattern.
    Example for n=4: 1010
    Returns both patterns: 1010 and 0101
    """
    pattern1 = int('10' * (n//2) + '1' * (n%2), 2)
    pattern2 = int('01' * (n//2) + '0' * (n%2), 2)
    return [format(pattern1, f'0{n}b'), format(pattern2, f'0{n}b')]

def generate_alternating_ones(n):
    """
    Generate n-bit alternating ones pattern.
    Example for n=4: 0101
    Returns both patterns: 0101 and 1010
    """
    pattern1 = int('01' * (n//2) + '0' * (n%2), 2)
    pattern2 = int('10' * (n//2) + '1' * (n%2), 2)
    return [format(pattern1, f'0{n}b'), format(pattern2, f'0{n}b')]

def generate_sliding_ones(n, window_size=2):
    """
    Generate n-bit sliding ones pattern with specified window size.
    Example for n=4, window_size=2: 0011, 0110, 1100
    """
    if window_size > n:
        raise ValueError("Window size cannot be larger than n")
    
    patterns = []
    # Create initial pattern with 'window_size' number of 1s
    initial_pattern = (1 << window_size) - 1
    
    for i in range(n - window_size + 1):
        pattern = initial_pattern << i
        patterns.append(format(pattern, f'0{n}b'))
    return patterns

def generate_sliding_zeros(n, window_size=2):
    """
    Generate n-bit sliding zeros pattern with specified window size.
    Example for n=4, window_size=2: 1100, 0110, 0011
    """
    if window_size > n:
        raise ValueError("Window size cannot be larger than n")
    
    patterns = []
    # Create initial pattern with 'window_size' number of 0s
    all_ones = (1 << n) - 1
    window_mask = (1 << window_size) - 1
    
    for i in range(n - window_size + 1):
        pattern = all_ones & ~(window_mask << i)
        patterns.append(format(pattern, f'0{n}b'))
    return patterns

def generate_powers_of_two_minus_one(n):
    """
    Generate n-bit powers of 2 minus 1 pattern.
    Example for n=4: 0001, 0011, 0111, 1111
    """
    patterns = []
    power = 1
    while power < (1 << n):
        patterns.append(format(power - 1, f'0{n}b'))
        power <<= 1
    # Add the last pattern which is all ones
    patterns.append(format((1 << n) - 1, f'0{n}b'))
    return patterns

def generate_random_binary(n):
    """
    Generate a random binary string of length n
    """
    if n < 0:
        raise ValueError("Length must be non-negative")
        
    binary_string = ''.join(random.choices(['0', '1'], k=n))
    
    return binary_string

#*************************************************************************
# END OF FILE
#*************************************************************************