# ======================================================================
# Tiny Tapeout SystemVerilog tests (VCS)
# ======================================================================

SIM ?= vcs

# Paths local to this Makefile
TEST_DIR      := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
PROJECT_ROOT  := $(abspath $(TEST_DIR)/..)
RUN_VCS       := $(TEST_DIR)/utils/run_vcs.mk

# Coverage output paths
COVERAGE_DIR  ?= coverage_work
COVERAGE_RPT  ?= coverage_reports

# Area estimate output paths
AREA_DIR      ?= area_estimate
AREA_SCRIPT   := $(AREA_DIR)/area_estimate.ys
AREA_REPORT   := $(AREA_DIR)/area_report.txt
AREA_REPORT_GENERIC := $(AREA_DIR)/area_report_generic.txt

# Common knobs
GEN_WAVES     ?= True
GEN_COVERAGE  ?= True
TEST          ?= 0
SIM_ARGS      += +test-case=$(TEST)

# Auto-discover tests in this folder (convention: *_test.sv)
TEST_FILES    := $(wildcard $(TEST_DIR)/*_test.sv)

# Synthesis/area knobs
SYNTH_TOP     ?= market_microstructure
SYNTH_SRC     ?= $(PROJECT_ROOT)/src/market_microstructure.v
OSS_CAD_SUITE ?= $(HOME)/tools/oss-cad-suite

# Common SG13G2 liberty locations (first existing path is used)
LIBERTY_HINTS := \
	$(TEST_DIR)/utils/sg13g2_stdcell_typ_1p20V_25C.lib \
	$(TEST_DIR)/utils/sg13g2_stdcell_typ_1p08V_25C.lib \
	$(HOME)/IHP-Open-PDK/ihp-sg13g2/libs.ref/sg13g2_stdcell/lib/sg13g2_stdcell_typ_1p20V_25C.lib \
	$(HOME)/IHP-Open-PDK/ihp-sg13g2/libs.ref/sg13g2_stdcell/lib/sg13g2_stdcell_typ_1p08V_25C.lib \
	$(PROJECT_ROOT)/pdk/ihp-sg13g2/libs.ref/sg13g2_stdcell/lib/sg13g2_stdcell_typ_1p20V_25C.lib
LIBERTY_AUTO  := $(firstword $(wildcard $(LIBERTY_HINTS)))
LIBERTY       ?= $(LIBERTY_AUTO)

# Common compile args
COMPILE_ARGS += +incdir+$(PROJECT_ROOT)
COMPILE_ARGS += +incdir+$(PROJECT_ROOT)/src
COMPILE_ARGS += +incdir+$(TEST_DIR)
COMPILE_ARGS += +incdir+$(TEST_DIR)/utils
COMPILE_ARGS += +define+GEN_WAVES=$(GEN_WAVES)
COMPILE_ARGS += +define+GEN_COVERAGE=$(GEN_COVERAGE)

# VCS coverage flags
ifeq ($(GEN_COVERAGE), True)
    CM_OPTS      := -cm line+cond+tgl+fsm+branch+assert
    COMPILE_ARGS += $(CM_OPTS)
endif

# ----------------------------------------------------------------------
# Targets
# ----------------------------------------------------------------------

.PHONY: %_test help list-tests coverage_reports clean area_estimate area_estimate_generic area_clean

help:
	@echo "Common targets:"
	@echo "  make spi_test                   # run the spi_test testbench"
	@echo "  make list-tests                 # list discovered *_test.sv files"
	@echo "  make area_estimate LIBERTY=...  # area with SG13G2 liberty"
	@echo "  make area_estimate_generic      # rough estimate without liberty"
	@echo ""
	@echo "Current auto-detected LIBERTY: $(if $(LIBERTY),$(LIBERTY),<none>)"

# Generic test rule (invoke as: make spi_test)
%_test:
	@mkdir -p $(COVERAGE_DIR)
	$(MAKE) -f $(RUN_VCS) compile \
		TOP=$@ \
		TEST_DIR=$(TEST_DIR) \
		EXECUTABLE_NAME=simv_$@ \
		SRC_FILES="$(PROJECT_ROOT)/src/market_microstructure.v $(TEST_DIR)/utils/test_utils.sv $(TEST_FILES)" \
		COMPILE_ARGS="$(COMPILE_ARGS)"
	./simv_$@ $(SIM_ARGS) \
		$(if $(filter True,$(GEN_COVERAGE)),$(CM_OPTS) -cm_dir $(COVERAGE_DIR)/simv_$@.vdb -cm_name $@,)

list-tests:
	@printf "%s\n" $(notdir $(TEST_FILES))

# ----------------------------------------------------------------------
# Area estimate (Yosys + Liberty)
# ----------------------------------------------------------------------

area_estimate:
	@command -v yosys >/dev/null 2>&1 || { \
		echo "ERROR: yosys not found in PATH."; \
		echo "If using OSS CAD Suite:"; \
		echo "  export OSS_CAD_SUITE=$(HOME)/tools/oss-cad-suite"; \
		echo "  . \"$$OSS_CAD_SUITE/environment\""; \
		exit 1; \
	}
	@test -f "$(SYNTH_SRC)" || { \
		echo "ERROR: RTL source not found: $(SYNTH_SRC)"; \
		exit 1; \
	}
	@test -n "$(LIBERTY)" || { \
		echo "ERROR: LIBERTY is not set and no default was found."; \
		echo "Example:"; \
		echo "  make area_estimate LIBERTY=/path/to/sg13g2_stdcell_typ_1p20V_25C.lib"; \
		exit 1; \
	}
	@test -f "$(LIBERTY)" || { \
		echo "ERROR: Liberty file not found: $(LIBERTY)"; \
		exit 1; \
	}
	@mkdir -p $(AREA_DIR)
	@printf '%s\n' \
		'read_verilog -I$(PROJECT_ROOT)/src $(SYNTH_SRC)' \
		'hierarchy -check -top $(SYNTH_TOP)' \
		'proc; opt; fsm; opt; memory; opt' \
		'techmap; opt' \
		'dfflibmap -liberty $(LIBERTY)' \
		'abc -liberty $(LIBERTY)' \
		'stat -liberty $(LIBERTY)' \
		> $(AREA_SCRIPT)
	yosys -s $(AREA_SCRIPT) | tee $(AREA_REPORT)
	@echo "Area report: $(AREA_REPORT)"

# Rough estimate without technology mapping
area_estimate_generic:
	@command -v yosys >/dev/null 2>&1 || { \
		echo "ERROR: yosys not found in PATH."; \
		exit 1; \
	}
	@test -f "$(SYNTH_SRC)" || { \
		echo "ERROR: RTL source not found: $(SYNTH_SRC)"; \
		exit 1; \
	}
	@mkdir -p $(AREA_DIR)
	yosys -p 'read_verilog -I$(PROJECT_ROOT)/src $(SYNTH_SRC); hierarchy -check -top $(SYNTH_TOP); proc; opt; fsm; opt; memory; opt; techmap; opt; stat' | tee $(AREA_REPORT_GENERIC)
	@echo "Generic report: $(AREA_REPORT_GENERIC)"

area_clean:
	rm -rf $(AREA_DIR) .fsm.sch.verilog.xml

# ----------------------------------------------------------------------
# Coverage report targets (urg)
# ----------------------------------------------------------------------

coverage_reports:
	@echo "Generating unified coverage report from $(COVERAGE_DIR)..."
	mkdir -p $(COVERAGE_RPT)
	urg -dir $(COVERAGE_DIR)/*.vdb -report $(COVERAGE_RPT)/all_sv_coverage -format both
	@echo "Report generated at $(COVERAGE_RPT)/all_sv_coverage/dashboard.html"

# ----------------------------------------------------------------------
# Clean
# ----------------------------------------------------------------------

clean:
	rm -rf simv* csrc *.daidir *.vcd *.ucdb $(COVERAGE_DIR) $(COVERAGE_RPT) ucli.key cm.log .fsm.sch.verilog.xml
