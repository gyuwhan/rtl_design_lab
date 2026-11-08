# 토글 동기화기

## 필요한 이유

- 서로 다른 클럭 도메인 간 펄스 신호를 전송할 때, 기존 2ff으로 수신하게 되면, 펄스가 수신 클럭 주기보다 짧아 에지 사이에서 무시되는 경우, 첫 번째 엣지에서 이전 값으로 안정화, 다음 엣지에서 새로운 값으로 안정화되면 펄스 신호를 무시하게 되는 단점들이 있다.
이때 토글 동기화기를 추가하면, 펄스를 토글 레벨 신호로 만들어 수신 측에서 펄스 신호를 안정적으로 캡쳐할 수 있다.

1. 사양
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

