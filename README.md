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

`docker compose up`으로 PostgreSQL·RabbitMQ·FastAPI를 동시에 띄우면, `depends_on`은 컨테이너 "시작"만 보장할 뿐 내부 서비스가 실제로 요청을 받을 준비가 됐는지는 보장하지 않습니다. 이로 인해 FastAPI가 PostgreSQL 초기화가 끝나기 전에 연결을 시도해 실패하는 문제가 있었습니다.

- `server/fastapi/mqtt_client.py`의 `start_mqtt()`에 재시도 로직(최대 10회, 3초 간격)을 추가해 RabbitMQ 기동 지연에 대응
- GCE VM 배포 스크립트(`terraform/startup.sh`)에서는 `docker compose up -d --build` 실행 후 `sleep 15` 뒤 `docker restart scada-fastapi`로 FastAPI를 재기동시켜 PostgreSQL 초기화 시간을 확보

로컬 개발 환경에서 동일한 증상이 재현되면 컨테이너를 재시작하거나, healthcheck 기반 `depends_on` 조건으로 개선할 여지가 있습니다. [작성 필요]
</details>

<details>
<summary>GCE VM에 Docker 설치 실패 (docker.io / docker-compose-v2 패키지 이슈)</summary>

초기에는 `apt-get install docker.io docker-compose-v2`로 설치했으나, Debian 12(`debian-cloud/debian-12`) 이미지에서 패키지 버전 문제로 설치가 실패했습니다. Docker 공식 설치 스크립트(`curl -fsSL https://get.docker.com | sh`)로 교체해 Debian/Ubuntu 환경에서 안정적으로 설치되도록 해결했습니다.
</details>

<details>
<summary>RabbitMQ(MQTT) 자체 서명 TLS 인증서 검증 오류</summary>

게이트웨이 ↔ 서버 통신에 TLS(8883 포트)를 적용하는 과정에서, 자체 서명(self-signed) 인증서를 사용하다 보니 클라이언트 측 인증서 체인 검증이 실패하는 문제가 있었습니다. `mqtt_client_tls.py`에서 `cert_reqs=ssl.CERT_NONE`과 `tls_insecure_set(True)`로 검증을 우회해 테스트 환경에서는 통신이 가능하도록 했습니다. 운영 환경에서는 정식 CA 인증서로 교체하는 것이 필요합니다. [작성 필요 — 정식 인증서 전환 계획]
</details>

<details>
<summary>게이트웨이-서버 간 시간 동기화 (레이턴시 측정)</summary>

게이트웨이와 서버의 시스템 시계가 어긋나면 종단 간 지연 시간을 정확히 측정할 수 없어, 게이트웨이 쪽에서 `ntplib`으로 NTP 서버(`time.google.com`) 시각을 받아와 타임스탬프(`t3`, `received_at`)를 찍고, 서버 응답에도 `server_send_time`을 포함시켜 UI에서 구간별 지연을 계산할 수 있도록 했습니다. 정확히 어떤 구간에서 지연이 가장 컸는지, NTP 요청 실패 시 폴백 처리 방식 등 세부 내용은 [작성 필요]
</details>
