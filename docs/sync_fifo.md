# sync_fifo

## 1. 사양
- 파라미터: DEPTH = 8, WIDTH = 10, PTR = $clog2(DEPTH) + 1
- 포트: input: clk/1, rst_n/1, wr_data/WIDTH, rd_en/1, wr_en/1
       output: rd_data/WIDTH, empty/1, full/1
- 리셋 : Sync reset, Active low, reset 이후 wr_ptr, rd_ptr, rd_data = 0
- empty 일 때 rd_en=1, wr_en=1: rd_en 무시, wr_data 저장
- full일 때 wr_en=1: 무시한다.
- 동시 R/W: full에서 READ만 수행, empty에서 WRITE만 수행, 보통 상태에서 동시 R/W 지원(wr_ptr, rd_ptr 모두 1증가)
- DEPTH는 2 이상2의 거듭제곱만 지원(extra MSB)
- rd_data는 rd_en 다음 클럭에 출력
- 읽기를 무시할 시 rd_data, rd_ptr 유지



## 2. full/empty 판정 방법
- extra MSB 방식 사용: 이후 Async까지 확장을 위함
- full: `wr_ptr[PTR-1] != rd_ptr[PTR-1] && wr_ptr[PTR-2:0] == rd_ptr[PTR-2:0]`
- empty: `wr_ptr == rd_ptr`


## 3. 예측표

기준: 엣지 전 값 / 같은 줄의 FULL·EMPTY로 판정 / DEPTH = 4, 포인터 3비트

| 사이클 | WR_EN | RD_EN | WR_DATA | WR_PTR | RD_PTR | FULL | EMPTY | RD_DATA | MEM[0:3] |
|---|---|---|---|---|---|---|---|---|---|
| 0/reset | 0 | 0 | X | XXX | XXX | X | X | X | XXXX |
| 1 | 1 | 0 | A | 000 | 000 | 0 | 1 | 0 | XXXX |
| 2 | 1 | 0 | B | 001 | 000 | 0 | 0 | 0 | AXXX |
| 3 | 0 | 1 | X | 010 | 000 | 0 | 0 | 0 | ABXX |
| 4 | 1 | 1 | C | 010 | 001 | 0 | 0 | A | ABXX |
| 5 | 1 | 0 | D | 011 | 010 | 0 | 0 | B | ABCX |
| 6 | 1 | 0 | E | 100 | 010 | 0 | 0 | B | ABCD |
| 7 | 1 | 0 | F | 101 | 010 | 0 | 0 | B | EBCD |
| 8 | 1 | 0 | G | 110 | 010 | 1 | 0 | B | EFCD |
| 9 | 1 | 1 | Y | 110 | 010 | 1 | 0 | B | EFCD |
| 10 | 0 | 1 | X | 110 | 011 | 0 | 0 | C | EFCD |
| 11 | 0 | 1 | X | 110 | 100 | 0 | 0 | D | EFCD |
| 12 | 0 | 1 | X | 110 | 101 | 0 | 0 | E | EFCD |
| 13 | 0 | 1 | X | 110 | 110 | 0 | 1 | F | EFCD |
| 14 | 1 | 1 | H | 110 | 110 | 0 | 1 | F | EFCD |
| 15 | 1 | 1 | I | 111 | 110 | 0 | 0 | F | EFHD |
| 16 | 0 | 1 | X | 000 | 111 | 0 | 0 | H | EFHI |
| 17 | 0 | 0 | X | 000 | 000 | 0 | 1 | I | EFHI |


## 4. 검증

### 확인 목록

| 무엇 | 조건 | 기대 결과 (포트) |
|---|---|---|
| reset | rst_n = 0인 상태로 posedge clk | empty = 1, full = 0, rd_data = 0 |
| 기본 쓰기·읽기 | empty에서 n번 쓴 뒤 n번 읽기 | n번째 쓴 값이 n번째 읽기에서 나온다 |
| full 판정 | empty = 1에서 DEPTH−1번 / DEPTH번 쓰기 | DEPTH−1번 뒤 full = 0, DEPTH번 뒤 full = 1 |
| full에서 쓰기 | full = 1에서 wr_en = 1로 posedge clk | full = 1 유지. 이후 DEPTH번 읽으면 empty = 1이고, full에서 쓴 값은 나오지 않는다 |
| full에서 동시 R/W | full = 1에서 wr_en = rd_en = 1로 posedge clk | 읽기만 수행. full = 0, rd_data = 가장 먼저 쓴 값. 이후 한 번 쓰면 full = 1 |
| empty 판정 | n번 쓴 뒤 n−1번 / n번 읽기 | n−1번 뒤 empty = 0, n번 뒤 empty = 1 |
| empty에서 읽기 | empty = 1에서 rd_en = 1로 posedge clk | empty = 1 유지, rd_data는 이전 값 그대로. 이후 쓰면 empty = 0 |
| empty에서 동시 R/W | empty = 1에서 wr_en = rd_en = 1로 posedge clk | 쓰기만 수행. empty = 0, rd_data 변화 없음. 이후 한 번 읽으면 그때 쓴 값이 나온다 |
| 보통 상태 동시 R/W | empty = full = 0에서 wr_en = rd_en = 1로 posedge clk | full·empty 그대로 0. rd_data에는 가장 먼저 쓴 값이 나오고, 동시에 쓴 값은 나중에 순서대로 나온다 |
| wrap-around | 누적으로 DEPTH보다 많이 쓰고 읽기 | 한 바퀴 넘은 뒤에도 쓴 순서대로 나오고, DEPTH만큼 차면 다시 full = 1 |
| rd_data 타이밍 | empty = 0에서 rd_en = 1 | 읽기가 받아들여진 사이클의 다음 클럭에 rd_data가 바뀐다. 1개 쓰고 읽으면 그 클럭에 empty = 1 |

### 랜덤 TB 설계 (tb/tb_sync_fifo_rand.v)

DUT 파라미터: DEPTH = 4, WIDTH = 10

#### 랜덤 입력

- 랜덤으로 줄 신호: wr_en, rd_en, wr_data
- 확률: wr_en 55%, rd_en 50% (각각 독립)
- 사이클 수: 1000
- seed: 1 (integer 변수, $random(seed))
- 경계 도달 확인: ref_cnt == DEPTH인 사이클 수, ref_cnt == 0인 사이클 수를 따로 세서 마지막에 출력.

#### 참조 모델

- 변수: [WIDTH-1:0]ref_q[0:DEPTH-1], [$clog2(DEPTH):0]ref_cnt
- 쓰기를 받는 조건: ref_cnt < DEPTH
- 읽기를 받는 조건: ref_cnt > 0
- 기대 full / 기대 empty: ref_cnt == DEPTH, ref_cnt == 0
- 쓰기만 받을 때: ref_q[ref_cnt]에 쓰기, ref_cnt + 1
- 읽기만 받을 때: ref_q[0]값 읽기, ref_cnt - 1, ref_q 내부 한 칸씩 당김
- 둘 다 받을 때: ref_q[0]값 읽고, ref_q 내부 한 칸씩 당긴 후,ref_cnt -1. 이후 ref_q[ref_cnt]에 쓰기, ref_cnt + 1,
- 기대 rd_data: 읽기를 받은 사이클의 다음 클럭에 출력, 읽기 받지 않을 경우 기존 rd_data 유지
- reset: ref_cnt = 0, rd_data = 0, full = 0, empty = 1

#### 비교 시점
- 입력 넣기: negedge clk (posedge에 넣으면 DUT와 race)
- 참조 모델 갱신: posedge clk (DUT와 같은 입력을 같은 시점에 받기 위해)
- 받을지 판단 기준: 갱신 **전** ref_cnt로 판단. ref_cnt != DEPTH면 쓰기, ref_cnt != 0이면 읽기를 받는다. 참조 모델은 DUT 출력(full, empty)을 읽지 않는다
- 비교 시점: negedge에서, 새 입력을 넣기 전
- 비교 항목:
  - full ↔ (ref_cnt == DEPTH)
  - empty ↔ (ref_cnt == 0)
  - rd_data ↔ ref_rd_data (rd_en && ref_cnt != 0일 때 저장한 ref_q[0])

#### 경계 도달 확인
- ref_cnt == DEPTH인 사이클 수, ref_cnt == 0인 사이클 수를 따로 세서 마지막에 출력
- 0이면 PASS라도 "경계 미도달"로 표시

#### 한 사이클 흐름

    negedge      : TB가 직전 결과를 비교 → wr_en, rd_en, wr_data를 넣음
    (사이클 동안) : 지금 full·empty(참조 모델은 ref_cnt)로 쓰기·읽기를 받을지 정해져 있음
    posedge      : 받은 쪽 포인터(ref_cnt) 갱신, 쓰기면 mem(ref_q) 저장, 읽기면 rd_data(ref_rd_data) 갱신
    posedge 직후 : 새 포인터로 full·empty가 다시 계산됨
    다음 negedge : 비교 → 다음 입력
    
### 검증 결과

- TB에서 DEPTH = 4로 인스턴스하고 예측표 순서대로 입력, 매 사이클 full, empty, rd_data 비교 -> PASS 확인
- 버그 주입 1 (wr_accept에서 !full 제거): [9] full 오류로 처음 검출. full에서 G가 써지며 아직 읽지 않은 C를 덮어썼고(EFCD → EFGD), 이후 C 대신 G가 읽힘. 쓰기가 DEPTH보다 많이 들어가 포인터 차이가 범위를 넘으면서, 11사이클에는 읽기만 했는데 full이 다시 1이 됨
- 버그 주입 2 (empty를 주소 비트만 비교): [8] empty 오류로 처음 검출. full 상태에서 empty도 1이 되어 읽기·쓰기가 모두 막히고 FIFO가 멈춤
- 버그 2를 처음 넣을 때 RTL 기본값(DEPTH = 8) 기준으로 [2:0]을 직접 적었는데, TB는 DEPTH = 4라 [2:0] 이 MSB를 포함한 포인터 전체여서 버그가 들어가지 않고 PASS가 나옴. 웨이브폼 확인 시 포인터가 MSB 1bit, 주소 2bit로 동작하는 것을 확인. 이후 파라미터를 기준으로 [PTR-2:0] 으로 수정 후 정상적으로 오류 검출 완료
- 버그를 되돌린 뒤 다시 PASS 확인


## 신호 분류

| 신호 | 종류 | 정해지는 방식 |
|---|---|---|
| clk, rst_n, rd_en, wr_en, wr_data | 입력 | - |
| empty | 조합 | `wr_ptr == rd_ptr` |
| full | 조합 | `wr_ptr[PTR-1] != rd_ptr[PTR-1] && wr_ptr[PTR-2:0] == rd_ptr[PTR-2:0]` |
| wr_accept | 조합 | full과 wr_en |
| rd_accept | 조합 | rd_en과 empty |
| mem | 순차 | wr_ptr, wr_accept를 보고 wr_data를 씀 |
| wr_ptr | 순차 | 기존 wr_ptr, wr_accept |
| rd_ptr | 순차 | 기존 rd_ptr, rd_accept |
| rd_data | 순차 | mem, rd_ptr, rd_accept |

## 설계 결정 기록
- 바이패스, full에서 동시 쓰기 수락은 고려했지만 기본형을 먼저 완성하기 위해 넣지 않음
- PTR은 DEPTH에서 계산되므로 localparam으로 둠
- mem에 reset은 각 셀에 0을 WRITE 하는 로직으로 합성되어 면적, 자원을 차지하고, mem에 reset을 하지 않아도 write가 되어 empty가 아닌 경우에만 read가 가능하므로 이전 값이 무엇이든 write로 덮어쓰기가 먼저 진행되어 reset 기능을 추가하지 않음
- mem 쓰기를 reset으로 막지 않음 — reset 후 포인터가 0이라 그 값은 읽히지 않음

