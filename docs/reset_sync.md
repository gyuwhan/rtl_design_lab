# 리셋 동기화기

## 필요한 이유

- 외부 리셋은 clk와 무관하게 풀리기 때문에 리셋 시 recovery, removal time 혹은 setup, hold time에 리셋 신호가 변해 메타스테빌리티가 발생하거나, 리셋 경로 지연으로 같은 클럭 소스의 ff이 다른 클럭 사이클에 리셋이 해제되어 다른 시점에 시작하게 될 수 있다. 이때 리셋 동기화기 사용 시 async assert, sync deassert 방식으로 이런 문제를 예방할 수 있다.

## 1. 사양

- 포트: input(clk/1, rst_async_n/1), output(rst_sync_n/1)
- 리셋: Async reset, Active low, 내부 ff1 = 0, rst_sync_n = 0
- 입력: ff1의 d는 1, 두 ff의 비동기 리셋 핀에 rst_async_n 연결
- 출력: 해제가 recovery, removal 구간에 걸려도, 그 에지에서 rst_sync_n은 리셋을 유지하면 0, d의 값을 받아도 ff1의 이전 값 0이라 출력이 0으로 유지된다. 이때 ff1이 0으로 안정되면 해제가 1클럭 더 늦어진다.
- 동작: 비동기 리셋이 들어오면, ff1, rst_sync_n 모두 0으로 초기화. 이후 리셋 해제 시 ff1에 1 인가, 다음 클럭 사이클에 rst_sync_n에 ff1 신호 전달로 동기 리셋 해제 신호 모듈에 전달.
- 해제 지연: rst_async_n 해제 후 2번째 에지에 rst_sync_n = 1, ff1이 0으로 안정되면 3번째 에지
- Async assert 방식을 사용해 리셋의 글리치를 막지 못한다.
- 리셋 트리의 recovery, removal은 sta를 통해 따로 타이밍을 조정해야 한다.

## 2. 예측표

| 시점 | rst_async_n | ff1 | rst_sync_n |
|---|---|---|---|
| E1 | 1 | 1 | 1 |
| E1과 E2 사이, 입력 1→0 | 0 | 0 | 0 |
| E2 | 0 | 0 | 0 |
| E2와 E3 사이, 입력 0→1 | 1 | 0 | 0 |
| E3 | 1 | 1 | 0 |
| E4 | 1 | 1 | 1 |
| E5 | 1 | 1 | 1 |

## 3. TB 확인 목록

| 무엇 | 조건 | 기대 결과 |
|---|---|---|
| 비동기 리셋 | `rst_async_n = 1`, `ff1 = 1`, `rst_sync_n = 1` 상태에서 에지 사이에 `rst_async_n = 0` | 에지를 기다리지 않고 `ff1 = 0`, `rst_sync_n = 0` |
| 리셋 유지 | `rst_async_n = 0` 상태에서 clk 에지가 지나감 | `ff1 = 0`, `rst_sync_n = 0` 유지 |
| 리셋 해제 | `rst_async_n = 0` 유지 후 에지 사이에 `rst_async_n = 1` | 에지 전까지 `ff1 = 0`, `rst_sync_n = 0` 유지. 1번째 에지에 `ff1 = 1`, `rst_sync_n = 0`. 2번째 에지에 `rst_sync_n = 1` |
| 짧은 리셋 | `rst_async_n = 1`, `ff1 = 1`, `rst_sync_n = 1` 상태에서 에지 사이에 `rst_async_n = 0`을 1ns 유지 후 1 | 바로 `ff1 = 0`, `rst_sync_n = 0`. 해제 지연이 처음부터 다시 시작해 2번째 에지에 `rst_sync_n = 1` |

확인 못 하는 것:
- 메타스터빌리티 발생 자체
- `rst_async_n`이 recovery, removal 구간에서 해제될 때의 동작
- 그에 따른 해제 지연 변화 (ff1이 1로 안정되면 2번째 에지, 0으로 안정되면 3번째 에지)

## 4. TB 시나리오

입력은 negedge에서 바꾼다. "#1 뒤 확인"은 입력 변경 1ns 뒤에 값을 확인한다.

| 단계 | 입력 변경 (negedge) | 지나갈 posedge 수 | 확인할 값 |
|---|---|---|---|
| 1 | `rst_async_n = 1` | 2 | `ff1 = 1`, `rst_sync_n = 1` |
| 2 | `rst_async_n = 0` | 0, #1 뒤 확인 | `ff1 = 0`, `rst_sync_n = 0` |
| 3 | 유지 | 2 | `ff1 = 0`, `rst_sync_n = 0` |
| 4 | `rst_async_n = 1` | 0, #1 뒤 확인 | `ff1 = 0`, `rst_sync_n = 0` |
| 5 | 유지 | 1 | `ff1 = 1`, `rst_sync_n = 0` |
| 6 | 유지 | 1 | `ff1 = 1`, `rst_sync_n = 1` |
| 7 | 유지 | 2 | `ff1 = 1`, `rst_sync_n = 1` |
| 8 | `rst_async_n = 0`, 1ns 뒤 `rst_async_n = 1` | 0, #1 뒤 확인 | `ff1 = 0`, `rst_sync_n = 0` |
| 9 | 유지 | 1 | `ff1 = 1`, `rst_sync_n = 0` |
| 10 | 유지 | 1 | `ff1 = 1`, `rst_sync_n = 1` |

- 1단계는 리셋 없이 시작해 첫 에지 뒤 `rst_sync_n = x`이고, 2번째 에지에 1이 된다.

## 5. 검증 결과

- 시나리오 10단계 PASS (`make sim`, 100ns)
- 버그 A, 동기 리셋: 2단계에서 즉시 리셋이 되지 않아 2번(21ns). 8단계 짧은 리셋은 posedge가 없어 리셋 신호를 놓치게 되어 3번(82ns 2건, 90ns 1건). 총 5건
- 버그 B, 1단 구조: 해제 후 1번째 에지에 `rst_sync_n`이 바로 1이 되어 5단계(50ns), 9단계(90ns)에서 2건
- 확인 못 한 것: 메타스터빌리티 발생, 해제가 recovery, removal 구간에 걸릴 때의 동작과 3번째 에지 지연