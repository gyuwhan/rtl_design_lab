# 사용법:
#   vivado -mode batch -nojournal -nolog -source scripts/vivado_synth.tcl \
#          -tclargs <top> <clk_port> <period_ns> <rtl files...>

# -tclargs 이후 인자들이 list $argv에 저장. 인자가 4개 미만일 경우 사용법 출력 후 종료
if {[llength $argv] < 4} {
    puts "usage: -tclargs <top> <clk_port> <period_ns> <rtl files...>"
    exit 1
}

# -tclargs로 받은 list $argv의 인자를 index 해서 1개씩 변수에 저장
# 순서대로 top, clk_port, period, 이후 끝까지 rtl 파일 순서로 입력해야 함
set top       [lindex $argv 0]
set clk_port  [lindex $argv 1]
set period    [lindex $argv 2]
set rtl_files [lrange $argv 3 end]

# 사용할 칩 변수에 저장, 출력 폴더 생성
set part   xc7a35tcpg236-1
set outdir build/$top
file mkdir $outdir

# foreach를 사용해서 반복
# rtl files 변수 내 rtl 파일들 모두 read_verilog 동작
foreach f $rtl_files {
    read_verilog $f
}

# top모듈 합성
# out of context 옵션으로 I/O 버퍼 생성 X
synth_design -top $top -part $part -mode out_of_context

# clk_port로 clk 이름의 주기 period(ns) 클럭이 들어온다고 가정
create_clock -name clk -period $period [get_ports $clk_port]

# report 생성
# timing summary: 전체 타이밍 위반 요약 확인
# timing -delay_type max: 최대 지연 기준 setup 검사, 최대 setup slack 경로 3개
# timing -delay_type min: 최소 지연 기준 hold 검사, 최대 hold slack 경로 3개
# utilization: 합성 후 LUT, FF, RAM등 자원 확인
report_timing_summary -file $outdir/timing_summary.rpt
report_timing -delay_type max -max_paths 3 -file $outdir/timing_setup.rpt
report_timing -delay_type min -max_paths 3 -file $outdir/timing_hold.rpt
report_utilization -file $outdir/utilization.rpt

# reports 경로 출력
puts "reports: $outdir"