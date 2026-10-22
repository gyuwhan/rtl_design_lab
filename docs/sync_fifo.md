# sync_fifo

## 1. 사양
- 파라미터: DEPTH = 8, WIDTH = 10, PTR = $clog2(DEPTH) + 1
- 포트: input: clk/1, rst_n/1, wr_data/WIDTH, rd_en/1, wr_en/1
       output: rd_data/WIDTH, empty/1, full/1
- 리셋 : Sync reset, Active low, reset 이후 wr_ptr, rd_ptr, rd_data = 0
- empty 일 때 rd_en=1, wr_en=1: rd_en 무시, wr_data 저장
- full일 때 wr_en=1: 무시한다.
- 동시 R/W: full에서 READ만 수행, empty에서 WRITE만 수행, 보통 상태에서 동시 R/W 지원(wr_ptr, rd_ptr 모두 1증가)
- DEPTH는 2의 거듭제곱만 지원(extra MSB)
- rd_data는 rd_en 다음 클럭에 출력
- 읽기를 무시할 시 rd_data, rd_ptr 유지



## 2. full/empty 판정 방법
- extra MSB 방식 사용: 이후 Async까지 확장을 위함
- full: `wr_ptr[PTR-1] != rd_ptr[PTR-1] && wr_ptr[PTR-2:0] == rd_ptr[PTR-2:0]`
- empty: `wr_ptr == rd_ptr`


## 3. 사이클별 예측표

기준: 엣지 전 값 / 같은 줄의 FULL·EMPTY로 판정 / DEPTH = 4, 포인터 3비트

| 사이클 | WR_EN | RD_EN | WR_DATA | WR_PTR | RD_PTR | FULL | EMPTY | RD_DATA | MEM[0:3] |
|---|---|---|---|---|---|---|---|---|---|
| 1 | 1 | 0 | A | 000 | 000 | 0 | 1 | X | XXXX |
| 2 | 1 | 0 | B | 001 | 000 | 0 | 0 | X | AXXX |
| 3 | 0 | 1 | X | 010 | 000 | 0 | 0 | X | ABXX |
| 4 | 1 | 1 | C | 010 | 001 | 0 | 0 | A | ABXX |
| 5 | 1 | 0 | D | 011 | 010 | 0 | 0 | B | ABCX |
| 6 | 1 | 0 | E | 100 | 010 | 0 | 0 | B | ABCD |
| 7 | 1 | 0 | F | 101 | 010 | 0 | 0 | B | EBCD |
| 8 | 1 | 0 | G | 110 | 010 | 1 | 0 | B | EFCD |
| 9 | 1 | 1 | X | 110 | 010 | 1 | 0 | B | EFCD |
| 10 | 0 | 1 | X | 110 | 011 | 0 | 0 | C | EFCD |
| 11 | 0 | 1 | X | 110 | 100 | 0 | 0 | D | EFCD |
| 12 | 0 | 1 | X | 110 | 101 | 0 | 0 | E | EFCD |
| 13 | 0 | 1 | X | 110 | 110 | 0 | 1 | F | EFCD |
| 14 | 1 | 1 | H | 110 | 110 | 0 | 1 | F | EFCD |
| 15 | 1 | 1 | I | 111 | 110 | 0 | 0 | F | EFHD |
| 16 | 0 | 0 | X | 000 | 111 | 0 | 0 | H | EFHI |

## 4. 신호 분류

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


