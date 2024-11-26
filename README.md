# CS6230 - Cad For VLSI
Hardware Design of a Multiply-Accumulate (MAC) Unit and Systolic Array for 4x4 Matrix Multiplication in Bluespec System Verilog

# Status
## Assignment 1:

1. int32 :
a. pipelined design: code - completed, verification - completed
b. unpipeined design : code - completed, verification - completed

2. bfloat16:
a. pipelined design: code - completed, verification - completed
b. unpipeined design : code - completed, verification - completed

## Assignment 2:

int32: code - completed, verification - not-completed
bfloat16: code - completed, verification - not-completed

## Steps to run CoCoTb verification
- Modify the Makefile to pick between the pipelined and unpipelined MAC design by commenting and uncommenting the necessary lines.
- Verilog files are already generated and present in ./verilog folder.
- Run *$make simulate* to run the CoCoTb simulation.
- Test patterns in *./verification_pipelined/test_mac.py* and *./verification_pipelined/test_mac.py* can be commented and uncommented based on the coverage we want to achieve. 

## Steps to generate Verilog files
- Modify the Makefile to pick between the pipelined and unpipelined MAC design by modifying the *TOPFILE* variable.
- *$make generate_verilog* to generate the verilog source.
- *$make clean_build* to clean the project directory and start fresh.
