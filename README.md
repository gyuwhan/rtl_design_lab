# RTL Design Lab

Verilog로 디지털 기본 블록을 설계하고 self-checking 테스트벤치로 검증하는 개인 학습 저장소입니다.
모듈마다 사양을 RTL 상단 주석에 적고, 테스트벤치가 기대값과 비교해 PASS/FAIL을 판정합니다.

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
| `docs/` | 환경 기록 |
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

### 실험

일부러 문제를 만들어 lint와 합성 결과를 비교한 모듈입니다. lint가 실패하는 것이 의도한 결과입니다.

| 모듈 | 내용 | 결과 |
|---|---|---|
| `shift_reg_blk_a` | 순차 블록에 blocking, `q1 = d` → `q2 = q1` → `q3 = q2` | 플립플롭 1개로 합성 (3단 지연 사라짐). lint `BLKSEQ` |
| `latch` | `else` 없는 `if`, 덜 쓴 `case`, 조합 자기참조 | `$dlatch` 3개. lint 경고 이름이 원인마다 다름 (`LATCH`, `CASEINCOMPLETE`, `UNOPTFLAT`) |
| `latch_fixed` | 위 세 블록을 수정 | lint 경고 0개, `$dlatch` 0개 |