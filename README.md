# RTL Design Lab

Verilog 기반 디지털 회로를 직접 설계하고 검증하는 개인 프로젝트 저장소입니다. 사양, RTL, self-checking 테스트벤치, 실행 결과를 함께 기록합니다.

## 개발 환경

- WSL2 / Ubuntu
- Icarus Verilog: 컴파일 및 시뮬레이션
- Verilator: RTL lint
- Yosys: 합성 구조 확인
- GTKWave: 파형 확인

설치 버전은 [환경 기록](docs/tool-versions.txt)을 참고합니다.

## 디렉터리

| 경로 | 내용 |
|---|---|
| `rtl/` | 합성 대상 RTL |
| `tb/` | 테스트벤치 및 검증용 모델 |
| `docs/` | 사양, 설계 설명, 검증 결과 |
| `scripts/` | 자동화 스크립트 |
| `sim/` | 실행 파일, 로그, 파형 — Git 추적 제외 |

## 실행 방법

프로젝트 루트에서 실행합니다.

```bash
# 도움말
make help

# RTL과 TB 작성 후 실행
make sim TOP=mux2to1
make lint TOP=mux2to1
make synth-check TOP=mux2to1
make wave TOP=mux2to1

# 생성 파일 정리
make clean
```

`TOP=mux2to1`은 다음 파일과 모듈 이름을 기준으로 합니다.

- RTL: `rtl/mux2to1.v` / 모듈 `mux2to1`
- TB: `tb/tb_mux2to1.v` / 모듈 `tb_mux2to1`
- TB의 파형 저장 경로: `sim/mux2to1.vcd`

`make wave`는 시뮬레이션을 다시 실행한 후 파형을 엽니다. `make clean`은 `sim/`의 `.vvp`, `.vcd`, `.log` 파일과 `obj_dir/`를 삭제합니다.

테스트의 PASS/FAIL은 TB에서 판정합니다. Yosys 검사 성공은 latch 부재나 FPGA 타이밍 충족을 보장하지 않습니다.