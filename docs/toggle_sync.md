# 토글 동기화기

## 필요한 이유

- 서로 다른 클럭 도메인 간 펄스 신호를 전송할 때, 기존 2ff으로 수신하게 되면, 펄스가 수신 클럭 주기보다 짧아 에지 사이에서 무시되는 경우, 첫 번째 엣지에서 이전 값으로 안정화, 다음 엣지에서 새로운 값으로 안정화되면 펄스 신호를 무시하게 되는 단점들이 있다.
이때 토글 동기화기를 추가하면, 펄스를 토글 레벨 신호로 만들어 수신 측에서 펄스 신호를 안정적으로 캡쳐할 수 있다.

## 1. 사양

- 목표: clk_src의 1클럭 펄스 하나를 clk_dst의 1클럭 펄스 하나로 전달
- 전제: pulse_src는 clk_src에 동기된 펄스, 이벤트당 정확히 1클럭
- 포트: input(clk_src/1, rst_src_n/1, pulse_src/1, clk_dst/1, rst_dst_n/1), output(pulse_dst/1)
- 리셋: src, dst 측 모두 Sync reset, Active low, rst_src_n = 0 시 tog_src = 0, rst_dst_n = 0 시 tog_sync, tog_dly, ff1 = 0
- 내부 신호: tog_src(src에 동기된 토글 레벨 신호), tog_sync(tog_src를 2ff으로 받아 출력하는 신호), tog_dly(tog_sync를 ff으로 받아 dst 기준 1클럭 지연시킨 신호), ff1(2ff 입력 받는 ff)
- 동작: pulse_src 에 clk_src 기준 1클럭 펄스 입력 시 tog_src 신호 토글, 2ff에서 이 신호를 받아 tog_sync 신호 출력, 이 신호를 ff으로 받아 tog_dly 신호 출력. tog_sync와 tog_dly 신호를 XOR 해 pulse_dst 출력.
- 출력 지연: tog_src 변화 후 2번째 clk_dst 에지에 pulse_dst = 1, 3번째 에지에 0 (clk_dst 1클럭 폭). 메타스터빌리티로 ff1이 이전 값에 안정되면 각각 1에지 늦어짐
- 토글 신호 캡쳐 간 간격(레벨 폭)이 Tdst + Tsetup(ff1) + Thold(ff1) 초과인 신호만 정상적으로 사용 가능. 만약 간격이 더 작을 경우 두 펄스 신호를 모두 캡쳐하지 못할 수 있음. 여유를 두면 수신 2~3클럭 이상 간격 두기.
- 수신 확인 신호가 없어, 송신 측은 전달이 완료되었는지 알 수 없음.

## 2. 예측표

| 받는 쪽 에지 | tog_src | sync_2ff 내부 ff1 | tog_sync | tog_dly | pulse_dst |
|---|---|---|---|---|---|
| D1 | 0 | 0 | 0 | 0 | 0 |
| D2 | 1 | 1 | 0 | 0 | 0 |
| D3 | 1 | 1 | 1 | 0 | 1 |
| D4 | 1 | 1 | 1 | 1 | 0 |
| D5 | 1 | 1 | 1 | 1 | 0 |

## 3. TB 확인 목록

| 무엇 | 조건 | 기대 결과 |
|---|---|---|
| 리셋 | `rst_src_n = 0`, `rst_dst_n = 0` | `tog_src`, `ff1`, `tog_sync`, `tog_dly`, `pulse_dst` = 0 |
| 0→1 전달 | `tog_src = 0`에서 `pulse_src` 1클럭 | `tog_src = 1`. 변화 후 1번째 clk_dst 에지에 `ff1 = 1`, 2번째에 `tog_sync = 1`, `pulse_dst = 1`, 3번째에 `tog_dly = 1`, `pulse_dst = 0` |
| 1→0 전달 | `tog_src = 1`에서 `pulse_src` 1클럭 | 위와 같은 에지 순서로 0이 전달되고 `pulse_dst`는 clk_dst 1클럭 동안 1 |
| 여러 번 전송 | 간격 조건을 지킨 `pulse_src` N개 | 받은 `pulse_dst` 수 = N |
| 간격 위반 | 두 `pulse_src` 사이에 clk_dst 에지가 없도록 clk_src 2클럭 간격 | `ff1`, `tog_sync` 변화 없음, `pulse_dst = 0`. 두 이벤트 모두 유실 |
| 전송 중 양쪽 리셋 | `ff1 != tog_sync`일 때 두 리셋 모두 0 | 모든 값 0, 리셋 해제 후에도 `pulse_dst` 없음 (전송 중이던 펄스 신호 유실) |
| dst만 리셋 | `tog_src = 1` 상태에서 `rst_dst_n`만 0 후 해제 | 새 `pulse_src` 없이 해제 후 2번째 clk_dst 에지에 `pulse_dst = 1` (가짜 펄스) |

확인 못 하는 것:
- 메타스터빌리티로 인한 1에지 추가 지연과 MTBF
- 간격 조건의 setup/hold 부분. RTL 시뮬레이션은 setup/hold를 모델링하지 않아 `Tdst`만 확인할 수 있다

## 4. TB 시나리오

clk_src posedge: 5, 15, 25, … ns / clk_dst posedge: 12.5, 37.5, 62.5, … ns

| 단계 | 입력 변경 시각 | 입력 변경 | 확인 시각 | 확인할 값 |
|---|---|---|---|---|
| 1 | 1ns | `rst_src_n = 0`, `rst_dst_n = 0` | 20ns | `tog_src`, `ff1`, `tog_sync`, `tog_dly`, `pulse_dst` = 0 |
| 2 | 20ns | 두 리셋 1, `pulse_src = 1` | 30ns | `tog_src = 1` |
| 3 | 30ns | `pulse_src = 0` | 50ns | `ff1 = 1`, `tog_sync = 0` |
| 4 | - | - | 80ns | `tog_sync = 1`, `tog_dly = 0`, `pulse_dst = 1` |
| 5 | 80ns | `pulse_src = 1` | 90ns | `tog_src = 0`, `ff1 = 0`, `tog_sync = 1`, `tog_dly = 1`, `pulse_dst = 0` |
| 6 | 90ns | `pulse_src = 0` | 120ns | `tog_sync = 0`, `tog_dly = 1`, `pulse_dst = 1` |
| 7 | - | - | 140ns | `tog_dly = 0`, `pulse_dst = 0` |
| 8 | 150ns | `pulse_src = 1` | 160ns | `tog_src = 1`, `pulse_dst = 0` |
| 9 | 160ns | `pulse_src = 0` | 180ns | `ff1 = 1`, `tog_sync = 0` |
| 10 | - | - | 190ns | `tog_sync = 1`, `tog_dly = 0`, `pulse_dst = 1` |
| 11 | 190ns | `pulse_src = 1` (205ns까지 유지, 이벤트 2개) | 200ns | `tog_src = 0` |
| 12 | 210ns | `pulse_src = 0` | 220ns | `tog_src = 1`, `ff1 = 1`, `tog_sync = 1`, `tog_dly = 1`, `pulse_dst = 0` |
| 13 | - | - | 250ns | `pulse_dst = 0`, `sent = 5`, `recv = 3` |
| 14 | 250ns | `rst_dst_n = 0` | 270ns | `tog_src = 1`, `ff1`, `tog_sync`, `tog_dly`, `pulse_dst` = 0 |
| 15 | 270ns | `rst_dst_n = 1` | 300ns | `ff1 = 1`, `tog_sync = 0` |
| 16 | - | - | 320ns | `tog_sync = 1`, `tog_dly = 0`, `pulse_dst = 1` (가짜 펄스) |
| 17 | - | - | 350ns | `tog_dly = 1`, `pulse_dst = 0` |
| 18 | 350ns | `pulse_src = 1` | 360ns | `tog_src = 0` |
| 19 | 360ns | `pulse_src = 0` | 370ns | `ff1 = 0`, `tog_sync = 1` |
| 20 | 370ns | 두 리셋 0 | 400ns | `tog_src`, `ff1`, `tog_sync`, `tog_dly`, `pulse_dst` = 0 |
| 21 | 400ns | 두 리셋 1 | 450ns | 모두 0 (해제 후 2번째 에지 437.5ns 이후에도 `pulse_dst` 없음) |