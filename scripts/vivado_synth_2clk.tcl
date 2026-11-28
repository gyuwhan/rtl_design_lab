# 사용법:
#   vivado -mode batch -nojournal -nolog -source scripts/vivado_synth_2clk.tcl \
#          -tclargs <top> <tag> <clk_a_port> <period_a_ns> <clk_b_port> <period_b_ns> <rtl files...>
#   예: -tclargs async_fifo mem_rst w_clk 10 r_clk 27.027 rtl/async_fifo.v rtl/sync_2ff.v rtl/reset_sync.v

if {[llength $argv] < 7} {
    puts "usage: -tclargs <top> <tag> <clk_a_port> <period_a_ns> <clk_b_port> <period_b_ns> <rtl files...>"
    exit 1
}

set top       [lindex $argv 0]
set tag       [lindex $argv 1]
set clk_a     [lindex $argv 2]
set period_a  [lindex $argv 3]
set clk_b     [lindex $argv 4]
set period_b  [lindex $argv 5]
set rtl_files [lrange $argv 6 end]

set part   xc7a35tcpg236-1
set outdir build/${top}_${tag}
file mkdir $outdir

foreach f $rtl_files {
    read_verilog $f
}

synth_design -top $top -part $part -mode out_of_context

# 클럭 두 개를 각각 정의 (클럭 이름 = 포트 이름)
create_clock -name $clk_a -period $period_a [get_ports $clk_a]
create_clock -name $clk_b -period $period_b [get_ports $clk_b]

# 두 클럭은 서로 비동기: 도메인 사이 경로는 setup/hold 검사에서 뺀다
set_clock_groups -asynchronous -group [get_clocks $clk_a] -group [get_clocks $clk_b]

report_timing_summary -file $outdir/timing_summary.rpt
report_timing -delay_type max -max_paths 3 -file $outdir/timing_setup.rpt
report_timing -delay_type min -max_paths 3 -file $outdir/timing_hold.rpt
report_utilization -file $outdir/utilization.rpt
report_cdc -details -file $outdir/cdc.rpt

puts "reports: $outdir"