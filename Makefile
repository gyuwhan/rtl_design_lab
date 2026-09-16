# Run from the repository root. Recipe indentation uses literal tabs.
SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := help

EXC := clean help
ifneq ($(filter-out $(EXC),$(MAKECMDGOALS)),)
	ifeq ($(strip $(TOP)),)
		$(error TOP 모듈을 지정해주세요. 사용방법: make <target> TOP=<module>)
	endif
endif

RTL_DIR := rtl
TB_DIR := tb
SIM_DIR := sim

RTL_SRC := $(RTL_DIR)/$(TOP).v
TB_SRC := $(TB_DIR)/tb_$(TOP).v
TB_TOP := tb_$(TOP)
OUT_VVP := $(SIM_DIR)/$(TOP).vvp
OUT_VCD := $(SIM_DIR)/$(TOP).vcd

.PHONY: help sim wave lint synth-check clean

help:
	@echo "사용방법: make <target> TOP=<module>"
	@echo "sim         컴파일 후 실행; 컴파일과 실행 로그 저장"
	@echo "wave        시뮬레이션 후 <module>.vcd 파일 확인 후 gtkwave로 실행"
	@echo "lint        Verilator lint 실행; 로그 저장;"
	@echo "synth-check Yosys 합성 구조 검사; 로그 저장"
	@echo "clean       시뮬레이션 파일 삭제"
	@echo "예시: make sim TOP=mux2to1"

sim: $(RTL_SRC) $(TB_SRC)
	@mkdir -p $(SIM_DIR)
	iverilog -g2012 -Wall -s $(TB_TOP) -o $(OUT_VVP) $(TB_SRC) $(RTL_SRC) \
		2>&1 | tee $(SIM_DIR)/$(TOP)_compile.log
	@rm -f $(OUT_VCD)
	vvp $(OUT_VVP) 2>&1 | tee $(SIM_DIR)/$(TOP)_run.log

wave: sim
	@test -f $(OUT_VCD) || { echo "$(OUT_VCD)파일이 없습니다.: TB dump를 확인하세요."; exit 1; }
	gtkwave $(OUT_VCD) &

lint: $(RTL_SRC)
	@mkdir -p $(SIM_DIR)
	verilator --lint-only -Wall --top-module $(TOP) $(RTL_SRC) \
		2>&1 | tee $(SIM_DIR)/$(TOP)_lint.log
		@echo "$(TOP) lint 통과"

synth-check: $(RTL_SRC)
	@mkdir -p $(SIM_DIR)
	yosys -p "read_verilog -sv $(RTL_SRC); hierarchy -check -top $(TOP); proc; opt; check -assert; stat" \
		2>&1 | tee $(SIM_DIR)/$(TOP)_synth.log
	@echo "합성 구조 검사 완료. 로그에서 래치를 확인하세요."

clean:
	rm -f $(SIM_DIR)/*.vvp $(SIM_DIR)/*.vcd $(SIM_DIR)/*.log
	rm -rf obj_dir
	@echo "시뮬레이션 파일 삭제 완료."
