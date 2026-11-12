# CDC

## 4 phase handshake

### 1. 사양

- 파라미터: WIDTH/8
- 목표: 다른 클럭 도메인을 사용하는 모듈에서, 멀티비트 데이터 안정적인 전송
- 포트: Input(clk_src/1, rst_src_n/1, clk_dst/1, rst_dst_n/1, data_in/WIDTH, send/1), Output(data_out/WIDTH, busy/1, valid_dst/1)
- 리셋:  src, dst 측 모두 Sync reset, Active low, rst_src_n = 0 시 busy = 0, req = 0, ack_sync = 0, data_hold = 0 / rst_dst_n 시 ack = 0, data_out = 0, req_sync = 0, valid_dst = 0
- 내부 신호: ack/1(수신 측 데이터 수신 완료 신호), req/1(송신 측 데이터 전송 요청 신호), ack_sync/1(송신 측 2ff 통해 들어온 ack 신호), req_sync/1(수신 측 2ff 통해 들어온 req 신호), data_hold/WIDTH(busy == 0 && send 시 data_in 저장)
- 동작: 송신 측이 busy == 0일 때 보낼 데이터가 있는 경우 data_in에 전송 data, send = 1 모듈에 전송, 이후 busy = 1, req = 1, 수신 측 req_sync == 1 && ack == 0인 엣지에서 data_out에 data_hold 저장, 이후 ack = 1, ack_sync == 1 시 req = 0, req_sync == 0 시 ack = 0, ack_sync == 0 && req == 0 시 busy = 0(전송 완료 및 전송 대기)
- busy == 1 시 send 신호 무시.
- valid_dst = req_sync == 1 && ack == 0인 에지에서 1, 새로운 데이터 수신 신호. 다음 에지에 0 (레지스터, 1클럭 펄스)
- 한계: 한 번 전송에 도메인을 4번 건너 느림. 연속 전송에는 Async fifo 사용, 두 도메인을 함께 리셋한다고 가정 -> 한쪽만 리셋 시 toggle synchronizer의 경우처럼 req, ack 상태 어긋남.
- data_hold를 두어 send 이후 data_in 변경되어도 동작하도록 설계. 대신 WIDTH비트 레지스터 한 개 증가.

### 2. 예측표

메타스터빌리티가 없다고 가정한다. 괄호는 ff1이 이전 값으로 안정됐을 때다.

| 단계 | 도메인 | 시작 (어떤 변화 뒤) | 동기화 값이 바뀌는 에지 | 동작이 일어나는 에지 | 바뀌는 신호 |
|---|---|---|---|---|---|
| 0 | src | `send = 1`을 받은 에지 | - | 그 에지 | `req = 1`, `busy = 1`, `data_hold = data_in` |
| 1 | dst | `req` 0→1 뒤 | 변화 후 2번째 에지 `req_sync = 1` (3번째) | 변화 후 3번째 에지 (4번째) | `data_out = data_hold`, `ack = 1`, `valid_dst = 1` |
| 2 | src | `ack` 0→1 뒤 | 변화 후 2번째 에지 `ack_sync = 1` (3번째) | 변화 후 3번째 에지 (4번째) | `req = 0` |
| 3 | dst | `req` 1→0 뒤 | 변화 후 2번째 에지 `req_sync = 0` (3번째) | 변화 후 3번째 에지 (4번째) | `ack = 0` |
| 4 | src | `ack` 1→0 뒤 | 변화 후 2번째 에지 `ack_sync = 0` (3번째) | 변화 후 3번째 에지 (4번째) | `busy = 0` |

- valid_dst: `req` 0→1 변화 후 3번째 dst 에지부터 1클럭. `data_out`이 새 값으로 바뀌는 에지와 같다.
- 전송 한 번: 메타스터빌리티가 없으면 src 7에지(0단계 포함), dst 6에지. 도메인을 건널 때마다 1에지씩 늘 수 있어 최대 각각 약 2에지 길어질 수 있다.

### 3. TB 확인 목록

TB는 내부 dut의 신호를 기다림. 보낸 값은 배열에 순서대로 저장, `valid_dst = 1`인 에지마다 다음 값과 `data_out`을 비교. 에지 수는 파형으로 확인.

| 무엇 | 조건 | 기대 결과 |
|---|---|---|
| 한 번 전송 | `busy = 0`에서 값 A와 `send` 1클럭 | `valid_dst` 1클럭 동안 `data_out = A` |
| busy 중 send 무시 | `busy = 1`인 동안 값 B와 `send` 1클럭 | B는 `data_out`에 나오지 않고 받은 수에 들어가지 않음. `busy` 그대로 1 |
| data_hold 유지 | `send` 직후 `busy = 1`인 동안 `data_in`을 다른 값으로 바꿈 | `data_out`에는 `send` 때의 값이 도착 |
| 연속 전송 | `busy`가 0이 된 직후 바로 다음 `send` | 두 값이 순서대로 도착 |
| valid_dst 폭 | 모든 전송 | `valid_dst`가 연속 두 dst 에지에서 1이 아님 |
| 개수 | 전체 시나리오 끝 | 보낸 수(`!busy && send`) = 받은 수(`valid_dst`) |
| 클럭 비율 | src 10ns·dst 25ns, src 25ns·dst 10ns 두 번 실행 | 두 경우 모두 위 항목 PASS |

확인 못 한 것: 메타스터빌리티로 인한 에지 추가, 한쪽만 리셋했을 때의 동작

### 4. TB 시나리오

클럭은 파라미터 `T_SRC`, `T_DST`로 두고 (10, 25)와 (25, 10)으로 두 번 실행.

1. 두 리셋을 2 클럭 동안 0으로 둔 뒤 해제
2. A 전송 (`busy = 0`을 기다린 뒤 `send` 1클럭)
3. 바로 이어서, busy 중에 B와 `send` 1클럭 → 무시돼야 함. 이때 `busy = 1`인지 확인
4. 이어서 `data_in`을 C로 바꿔 둠 (보내지 않음)
5. `busy = 0`이 되자마자 D 전송
6. E 전송
7. `busy = 0`까지 기다린 뒤 보낸 수와 받은 수 비교, PASS/FAIL 출력