#TOPFILE=mac.bsv           # For unpipelined MAC
TOPFILE=mac_pipelined.bsv  # For pipelined MAC
BSVINCDIR=.:%/Libraries
BSCDEFINES=RV64
VERILOGDIR=verilog/
BUILDDIR=intermediate/
SIMDIR=sim/

#include verification_unpipelined/Makefile.verif  # For unpipelined MAC
include verification_pipelined/Makefile.verif     # For pipelined MAC

.PHONY: simulate
simulate: 
	@make SIM=verilator
#	@mkdir -p $(SIMDIR) $(BUILDDIR)
#	@bsc -u -sim -simdir ./sim -bdir ./intermediate -info-dir ./intermediate -elab +RTS -K4000M -RTS -check-assert  -keep-fires -opt-undetermined-vals -remove-false-rules -remove-empty-rules -remove-starved-rules -unspecified-to X -show-schedule -show-module-use  -suppress-warnings G0010:T0054:G0020:G0024:G0023:G0096:G0036:G0117:G0015 -D $(BSCDEFINES) -p $(BSVINCDIR) -g mkTb $(TOPFILE)
#	@bsc -e mkTb -sim -o ./out -simdir ./sim -bdir ./intermediate -info-dir ./intermediate -p $(BSVINCDIR)
#	@./out -V


.PHONY: generate_verilog
generate_verilog:
	@mkdir -p $(VERILOGDIR) $(BUILDDIR)
	@bsc -u -verilog -elab -vdir ./verilog -bdir ./intermediate -info-dir ./intermediate +RTS -K4000M -RTS -check-assert  -keep-fires -opt-undetermined-vals -remove-false-rules -remove-empty-rules -remove-starved-rules -remove-dollar -unspecified-to X -show-schedule -show-module-use  -suppress-warnings G0010:T0054:G0020:G0024:G0023:G0096:G0036:G0117:G0015 -D $(BSCDEFINES) -p $(BSVINCDIR) $(TOPFILE)

.PHONY: clean_build
clean_build:
	@make clean
	@rm -rf $(VERILOGDIR) $(BUILDDIR)
	@rm -rf verification/__pycache__
	@rm -rf results.xml cov*.yml
	@rm -rf *.vcd results.xml sim_build
	@echo "Cleaned"

