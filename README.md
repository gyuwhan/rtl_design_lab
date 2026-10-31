# RTL Design Lab

Verilog로 디지털 기본 블록을 설계하고 self-checking 테스트벤치로 검증하는 개인 학습 저장소입니다.
모듈마다 사양을 RTL 상단 주석이나 `docs/`의 설계 문서에 적고, 테스트벤치가 기대값과 비교해 PASS/FAIL을 판정합니다.

## 개발 환경

- WSL2 / Ubuntu 24.04
- Icarus Verilog: 컴파일 및 시뮬레이션
- Verilator: RTL lint (`--lint-only -Wall`)
- Yosys: 합성 구조 확인
- GTKWave: 파형 확인

설치 버전은 [docs/tool-versions.txt](docs/tool-versions.txt)에 기록했습니다.

## 디렉터리

| 경로 | 내용 |
|---|---|
| `rtl/` | 설계 코드 |
| `tb/` | 테스트벤치 |
| `docs/` | 환경 기록, 모듈별 설계 문서 |
| `sim/` | 실행 파일, 로그, 파형 (Git 추적 제외) |

## 실행 방법

프로젝트 루트에서 실행합니다. `TOP`은 소문자 `top`으로도 쓸 수 있습니다.

```bash
make help                        # 사용법
make sim         TOP=mux2to1     # 컴파일과 시뮬레이션
make lint        TOP=mux2to1     # Verilator lint
make synth-check TOP=mux2to1     # Yosys 합성 구조 확인
make check       TOP=mux2to1     # sim, lint, synth-check를 차례로 실행
make wave        TOP=mux2to1     # 시뮬레이션 후 GTKWave 실행
make clean                       # sim/의 생성 파일 삭제
```

`TOP=mux2to1`은 다음 이름을 기준으로 합니다.

- RTL: `rtl/mux2to1.v`, 모듈 `mux2to1`
- TB: `tb/tb_mux2to1.v`, 모듈 `tb_mux2to1`
- 파형: `sim/mux2to1.vcd`

PASS/FAIL은 테스트벤치가 판정합니다. Yosys 검사가 에러 없이 끝나도 latch가 없다는 뜻은 아니므로,
로그 끝의 부품 목록에서 `$dlatch` 유무를 직접 확인합니다. FPGA 타이밍 충족도 이 검사로는 확인하지 않습니다.

### RTL 파일이 여러 개인 TB

`make sim`은 RTL 파일 하나와 같은 이름의 TB를 기준으로 합니다. 아래 TB는 직접 컴파일합니다.
`lint`, `synth-check`는 모듈마다 `make`로 실행할 수 있습니다.

```bash
# 1011 검출기: Moore/Mealy 공용 TB
iverilog -g2012 -Wall -Wno-timescale -s tb_seq_det_1011 -o sim/seq_det_1011.vvp \
    tb/tb_seq_det_1011.v rtl/seq_det_1011_moore.v rtl/seq_det_1011_mealy.v
vvp sim/seq_det_1011.vvp

# SRAM BIST: SRAM 모델과 함께
iverilog -g2012 -Wall -Wno-timescale -s tb_sram_bist -o sim/sram_bist.vvp \
    tb/tb_sram_bist.v rtl/sram_bist.v rtl/sram.v
vvp sim/sram_bist.vvp

iverilog -g2012 -Wall -Wno-timescale -s tb_sram_bist_march -o sim/sram_bist_march.vvp \
    tb/tb_sram_bist_march.v rtl/sram_bist_march.v rtl/sram.v
vvp sim/sram_bist_march.vvp

# Sync FIFO: 랜덤 TB (참조 모델 비교)
iverilog -g2012 -Wall -Wno-timescale -s tb_sync_fifo_rand -o sim/sync_fifo_rand.vvp \
    tb/tb_sync_fifo_rand.v rtl/sync_fifo.v
vvp sim/sync_fifo_rand.vvp
```

## 모듈

### 조합회로

| 모듈 | 하는 일 | 확인한 것 |
|---|---|---|
| `mux2to1` | 2:1 선택기 | 입력 전 조합 비교 |
| `mux4to1` | 4:1 선택기 (`case`) | 64조합 전수 검사. RTL에 버그를 넣어 TB가 예상 개수(16개)의 FAIL을 내는지 확인 |
| `dec3to8` | 3비트 입력으로 8줄 중 하나를 켬 | 8조합 전수 검사. 기대값을 시프트로 독립 계산해 입력 0의 RTL 버그 발견 |
| `priority_enc8to3` | 8입력 우선순위 인코더 (7번 우선), `valid` 출력 | 256조합 전수 검사. 입력이 0일 때 번호 0, `valid` 0 |

### 순차회로

| 모듈 | 하는 일 | 확인한 것 |
|---|---|---|
| `shift_reg_nb` | 3단 shift register (nonblocking), 동기 리셋 | 입력 순서열과 3클럭 지연 기대값 비교. 플립플롭 3개 |
| `up_down_counter` | 4비트 카운터. 우선순위 리셋 > load > enable, 양방향 순환 | 8개 장면 확인. 동시 입력 시 우선순위, 15→0, 0→15 |
| `param_shift_reg` | 병렬 load, 양방향 shift (`WIDTH` ≥ 2) | 9단계 기대값 비교. 방향, 유지, 리셋 |
| `edge_detector` | 상승/하강 엣지 검출, 레지스터 출력 (입력은 동기 신호로 가정) | 14클럭 순서열 비교. 출력이 1클럭 늦고 폭이 1클럭 |
| `register_2r1w` | 16 x 16비트 register file, 읽기 2 / 쓰기 1, 조합 읽기 | 쓰기와 읽기, 두 창구의 write-first 우회(엣지 전 확인), `w_en`=0일 때 우회와 쓰기 차단 |

### FSM과 인터페이스

| 모듈 | 하는 일 | 확인한 것 |
|---|---|---|
| `seq_det_1011_moore`, `seq_det_1011_mealy` | "1011" 검출기 (overlapping 허용). Moore는 검출 다음 클럭, Mealy는 검출 즉시 `det` | 공용 TB로 같은 입력을 넣어 비교. overlapping 2회 검출, 검출 없는 순서열, 검출 후 상태 복귀. 출력 시점 차이와 Mealy의 짧은 펄스는 [docs/moore_mealy.md](docs/moore_mealy.md)에 정리 |
| `vr_proc` | valid/ready로 8비트 1개를 받아 `PROC_CYCLES` 클럭 처리 후 valid/ready로 내보냄 | 사이클별 예측표와 비교. 처리 중 `in_ready`=0, 응답 대기 중 `out_valid`·`out_data` 유지, 응답을 보내는 사이클에 다음 요청 수신. RESP의 `in_ready = out_ready`를 지우면 TB가 FAIL을 내는지 확인 |

### 메모리 테스트 (BIST)

| 모듈 | 하는 일 | 확인한 것 |
|---|---|---|
| `sram` | 시뮬레이션용 단일 포트 동기 SRAM (256 x 10비트). 읽기 지연 1, 쓸 때도 읽기 주소 갱신 | 아래 두 BIST TB에서 함께 사용 |
| `sram_bist` | 교육 과제 사양으로 다시 만든 BIST. 전체 주소에 3FF → 000 → 2AA를 쓰고 읽어 비교 | 정상이면 1541사이클에 완료. 첫 패턴 0번지, 마지막 패턴 255번지 고장의 검출 사이클 확인. 첫 주소 비교 제외와 마지막 비교 상태를 지우면 TB가 FAIL을 내는지 확인. 플립플롭 16개 |
| `sram_bist_march` | March C- BIST. ⇑(w0) → ⇑(r0,w1) → ⇑(r1,w0) → ⇓(r0,w1) → ⇓(r1,w0) → ⇓(r0) | 정상이면 2563사이클에 완료. 동작 중과 `DONE`에서 `bist_en` 무시. 원소 4(152번지), 원소 5(0번지) 고장의 검출 사이클 확인. RTL에 버그 2개를 넣어 TB가 잡는지 확인 (그중 하나는 고장 주입 시점을 옮겨야 잡힘). 플립플롭 17개 |

고장은 TB가 SRAM 모델의 값을 한 번 바꿔 넣는 방식입니다. 계속 고정된 stuck-at 고장이나 coupling·주소 디코더 고장은 SRAM 모델에 구현하지 않았으므로, 확인한 범위는 값을 바꿔 넣은 고장의 검출까지입니다.

### FIFO

| 모듈 | 하는 일 | 확인한 것 |
|---|---|---|
| `sync_fifo` | 파라미터화한 동기 FIFO (`DEPTH`는 2 이상의 2의 거듭제곱). 포인터에 1비트를 더한 extra MSB 방식으로 full/empty 판정. full이면 쓰기, empty면 읽기 무시. `rd_data`는 읽기를 받은 다음 클럭에 출력 | TB: DEPTH 4 사이클별 예측표 순서로 입력해 매 사이클 비교 (동시 R/W, full에서 쓰기, empty에서 읽기, wrap-around 2회). 랜덤 TB(`tb_sync_fifo_rand`): count 방식 참조 모델과 비교, seed 1, 1000사이클, full 158, empty 89사이클 도달 확인. RTL에 버그 2개를 넣어 두 TB 모두 FAIL을 내는지 확인. lint는 기본값과 DEPTH=16·WIDTH=8에서 모두 경고 0개. 사양·예측표·설계 결정은 [docs/sync_fifo.md](docs/sync_fifo.md) |


### 실험

일부러 문제를 만들어 lint와 합성 결과를 비교한 모듈입니다. lint가 실패하는 것이 의도한 결과입니다.

| 모듈 | 내용 | 결과 |
|---|---|---|
| `shift_reg_blk_a` | 순차 블록에 blocking, `q1 = d` → `q2 = q1` → `q3 = q2` | 플립플롭 1개로 합성 (3단 지연 사라짐). lint `BLKSEQ` |
| `latch` | `else` 없는 `if`, 덜 쓴 `case`, 조합 자기참조 | `$dlatch` 3개. lint 경고 이름이 원인마다 다름 (`LATCH`, `CASEINCOMPLETE`, `UNOPTFLAT`) |
| `latch_fixed` | 위 세 블록을 수정 | lint 경고 0개, `$dlatch` 0개 |