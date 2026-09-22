# scada-capstone

센서(온습도) 데이터를 엣지 게이트웨이에서 수집하여 클라우드로 전송하고, 웹 대시보드에서 모니터링/제어하는 SCADA 시스템입니다.

![Python](https://img.shields.io/badge/Python-3776AB?logo=python&logoColor=white)
![FastAPI](https://img.shields.io/badge/FastAPI-009688?logo=fastapi&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-4169E1?logo=postgresql&logoColor=white)
![MQTT](https://img.shields.io/badge/RabbitMQ%2FMQTT-FF6600?logo=rabbitmq&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-2496ED?logo=docker&logoColor=white)
![Terraform](https://img.shields.io/badge/Terraform-7B42BC?logo=terraform&logoColor=white)
![GCP](https://img.shields.io/badge/Google%20Cloud-4285F4?logo=googlecloud&logoColor=white)
![GitHub Actions](https://img.shields.io/badge/GitHub%20Actions-2088FF?logo=githubactions&logoColor=white)

> 이 레포지토리는 팀 캡스톤 프로젝트(scada-capstone)를 기반으로,
> 클라우드 인프라 자동화(CI/CD, IaC)를 개인적으로 확장 구현한 버전입니다.

## 프로젝트 배경

현장 장비들은 RS485 유선 통신 기반의 MODBUS RTU 프로토콜을 사용하는 폐쇄적 로컬 인프라로 구성되어 있습니다. 외부 인터넷망과 단절되어 있어 원격 접근·제어가 불가능했고, 현장 작업자가 매번 오프라인으로 직접 제어해야 하는 공간적 제약과 대응 시간 지연이라는 문제가 있었습니다.

이를 해결하기 위해, 서로 다른 프로토콜을 사용하는 현장 장비(MODBUS RTU)와 서버(MQTT)를 게이트웨이가 실시간으로 중계하여 데이터 수집과 원격 제어를 지원하는 게이트웨이 기반 소규모 SCADA 시스템을 구축했습니다.

## 아키텍처

```
[센서 하드웨어] --Modbus/RS485--> [gateway] --MQTT--> [RabbitMQ] --구독--> [FastAPI] --저장--> [PostgreSQL]
                                                                              |
                                                                              v
                                                                         [ui 대시보드] (REST API 조회/제어)
```

## 담당 범위

팀 캡스톤 프로젝트를 기반으로, 다음 항목은 개인적으로 설계·구현 및 확장한 부분입니다.

**개인 담당 / 확장**
- GCP 인프라 전반 (`terraform/` 프로비저닝, GCE VM 구성)
- CI/CD 파이프라인 (`.github/workflows/deploy.yml`)
- Docker 환경 구성 (`docker-compose.yml`, 컨테이너 오케스트레이션)
- FastAPI 백엔드 뼈대 설계 (`fastapi/main.py`, 라우터 구조)
- TLS 보안 강화 (`mqtt_client_tls.py`)

**팀 공동 작업**
- 센서/게이트웨이 하드웨어 연동 (Modbus 통신, 이상 탐지 로직)
- 웹 UI 대시보드

## 디렉터리 구조

```
scada-capstone/
├── gateway/        # 엣지 디바이스: Modbus 센서 읽기 → MQTT 발행
├── server/         # 클라우드 백엔드 (FastAPI + RabbitMQ(MQTT) + PostgreSQL, Docker Compose)
├── ui/             # 웹 대시보드 (정적 HTML/JS)
├── terraform/      # GCP 인프라 IaC (GCE VM 프로비저닝)
└── .github/workflows/deploy.yml  # main 브랜치 push 시 GCP VM에 자동 배포
```

### gateway/
| 파일 | 역할 |
|---|---|
| `main.py` | 메인 루프 — 센서 데이터 읽기 → 보안 검사 → MQTT 발행 |
| `modbus_client.py` | RS485/Modbus로 온습도 센서 통신 |
| `mqtt_client.py` / `mqtt_client_tls.py` | 클라우드 MQTT 브로커로 발행 (TLS 지원) |
| `security.py` | 임계값 기반 이상 탐지 |

### server/
| 파일 | 역할 |
|---|---|
| `docker-compose.yml` | RabbitMQ(MQTT), PostgreSQL, FastAPI 컨테이너 오케스트레이션 |
| `fastapi/main.py` | 앱 엔트리포인트, 라우터 등록 |
| `fastapi/routers/sensor.py` | 센서 최신값/이력 조회 API |
| `fastapi/routers/control.py` | 릴레이 제어 명령 발행 API |
| `fastapi/routers/slack.py` | Slack 알림 연동 |
| `fastapi/mqtt_client.py` | 게이트웨이가 보낸 MQTT 메시지 구독 → DB 저장 |

### ui/
정적 HTML/JS 대시보드 (`index.html`, `config.js`), 자체 `docker-compose.yml`로 배포.

### terraform/
GCP Compute Engine VM(`e2-micro`)과 방화벽 규칙을 정의. `startup.sh`를 부팅 스크립트로 주입.

## 실행 방법

### 서버 (로컬)
```bash
cd server
# .env 파일 작성 후 실행 (docker-compose.yml 참고)
docker compose up -d --build
```

FastAPI 서버는 `http://localhost:8000` 에서 기동됩니다.

### UI
```bash
cd ui
docker compose up -d --build
```

### 게이트웨이 (엣지 디바이스)
```bash
cd gateway
pip install -r requirements.txt
python main.py
```

## 인프라 / CI-CD

- **Terraform**: `terraform/` 에서 GCP VM을 프로비저닝합니다.
- **GitHub Actions** (`.github/workflows/deploy.yml`): 수동 실행(workflow_dispatch) 시 SSH로 GCP VM에 접속해 `git pull` 후 `server`, `ui`의 Docker Compose를 재빌드/재기동합니다.
- 비용 절감을 위해 GCP VM을 상시 운영하지 않으며, 배포는 필요 시 수동으로 실행합니다.

## API 요약 (FastAPI)

| Method | Endpoint | 설명 |
|---|---|---|
| GET | `/sensors/{slave_id}/data` | 최신 센서 데이터 조회 |
| GET | `/sensors/{slave_id}/history` | 센서 이력 조회 |
| POST | `/control/relay/{slave_id}` | 릴레이 제어 명령 전송 |
| GET | `/control/relay/{slave_id}/logs` | 릴레이 제어 로그 조회 |

## 트러블슈팅

<details>
<summary>컨테이너 기동 순서 문제 — FastAPI가 DB/MQTT 브로커보다 먼저 뜨는 이슈</summary>

`docker compose up`으로 PostgreSQL·RabbitMQ·FastAPI를 동시에 띄우면, `depends_on`은 컨테이너 "시작"만 보장할 뿐 내부 서비스가 실제로 요청을 받을 준비가 됐는지는 보장하지 않습니다. 이로 인해 FastAPI가 PostgreSQL 초기화가 끝나기 전에 연결을 시도해 실패하는 문제가 있었고, 이를 해결하기 위해 `server/fastapi/mqtt_client.py`의 `start_mqtt()`에 재시도 로직(최대 10회, 3초 간격)을 추가해 RabbitMQ 기동 지연에 대응했습니다. GCE VM 배포 스크립트(`terraform/startup.sh`)에서도 `docker compose up -d --build` 실행 후 `sleep 15` 뒤 `docker restart scada-fastapi`로 FastAPI를 재기동시켜 PostgreSQL 초기화 시간을 확보하는 방식으로 대응했으며, 근본적으로는 healthcheck 기반 `depends_on` 조건으로 개선할 여지가 있습니다.

</details>

<details>
<summary>80초까지 치솟는 레이턴시 — 슬라이딩 큐로 해결</summary>

대시보드 통신 로그에서 지연시간이 80초까지 비정상적으로 치솟는 현상이 발견됐습니다. 원인은 대시보드가 매 폴링마다 과거 데이터 50개를 통째로 요청하면서 FastAPI/DB에 병목이 발생하고, 그 결과 라즈베리파이가 보낸 패킷이 서버 대기열에 갇히는 구조적 문제였습니다. 이를 해결하기 위해 폴링 방식을 슬라이딩 큐 로직으로 전환해, 최초 1회만 과거 데이터 전체를 조회하고 이후로는 최신 데이터 1개만 요청하도록 바꿨고, 배열 길이가 50개를 초과하면 가장 오래된 데이터를 `shift`로 제거하는 고정 크기 큐로 구현했습니다. 이 과정에서 실시간 시스템은 폴링 방식의 데이터 요청 설계 자체가 지연시간에 직접 영향을 준다는 것을 확인했고, 증상만 보고 고치는 게 아니라 아키텍처 구조 문제까지 파고들어야 근본적인 해결이 된다는 걸 배웠습니다.

</details>

<details>
<summary>T3=T2 추상화 — 8.7초 가짜 지연</summary>

슬라이딩 큐 적용 후에도 8.7초의 설명되지 않는 지연이 남아있었습니다. 원인을 찾아보니 지연시간 계산 코드에서 서버 수신 시각(T2)과 서버 송신 시각(T3)을 동일한 값으로 처리하고 있었고, 그 사이의 DB 조회 시간이 통째로 네트워크 지연으로 잘못 누적되고 있었습니다. FastAPI `sensor.py`에 `server_send_time = time.time()`을 추가하고, `index.html`에서 T3을 `data.server_send_time * 1000`으로 분리해서 서버의 실제 송신 시점을 정확히 측정하도록 수정했습니다. 이를 통해 지연시간을 측정할 땐 서버 내부 처리 시간(Application Delay)과 순수 네트워크 레이턴시를 반드시 분리해야 정확한 값을 얻을 수 있다는 점을 배웠습니다.

</details>

<details>
<summary>MQTT TLS 적용 중 발생한 5가지 트러블슈팅</summary>

MQTT 통신에 TLS(포트 8883)를 적용하는 과정에서 여러 문제가 연쇄적으로 발생했습니다. 인증서 파일의 권한이 너무 제한적으로 설정되어 RabbitMQ 프로세스가 읽지 못하는 문제가 있어 `chmod 644`로 권한을 조정했고, 기존에 활성화되어 있던 `rabbitmq_web_mqtt` 플러그인이 TLS 리스너와 충돌을 일으켜 비활성화했습니다. 이어서 사용 중인 RabbitMQ 3.13 버전에서 설정 문법이 이전 버전과 달라 인식되지 않는 문제를 문서 확인 후 최신 문법으로 수정했고, TLS용 8883 포트를 열었음에도 기존 1883(non-TLS) 포트와 설정이 겹쳐 충돌하는 부분을 리스너 설정에서 분리했습니다. 마지막으로 게이트웨이 측 Python 코드에서 TLS 연결이 계속 실패했는데, `CERT_NONE`으로 인증서 검증을 명시하고 `PROTOCOL_TLSv1_2`를 직접 지정해야 한다는 걸 확인한 뒤에야 정상적으로 연결이 맺어졌습니다.

</details>
