# CS6230-CadForVLSI-Project1
Harwdware Design of a Multiply-Accumulate (MAC) Unit in Bluespec System Verilog

## Steps to run CoCoTb verification
- Modify the Makefile to pick between the pipelined and unpipelined MAC design by commenting and uncommenting the necessary lines.
- Verilog files are already generated and present in ./verilog folder.
- Run *$make simulate* to run the CoCoTb simulation.
- Test patterns in *./verification_pipelined/test_mac.py* and *./verification_pipelined/test_mac.py* can be commented and uncommented based on the coverage we want to achieve. 

## Steps to generate Verilog files
- Modify the Makefile to pick between the pipelined and unpipelined MAC design by modifying the *TOPFILE* variable.
- *$make generate_verilog* to generate the verilog source.
- *$make clean_build* to clean the project directory and start fresh.