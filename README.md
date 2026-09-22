# scada-capstone

센서(온습도) 데이터를 엣지 게이트웨이에서 수집하여 클라우드로 전송하고, 웹 대시보드에서 모니터링/제어하는 SCADA 시스템입니다.

> 이 레포지토리는 팀 캡스톤 프로젝트(scada-capstone)를 기반으로,
> 클라우드 인프라 자동화(CI/CD, IaC)를 개인적으로 확장 구현한 버전입니다.

## 아키텍처

```
[센서 하드웨어] --Modbus/RS485--> [gateway] --MQTT--> [RabbitMQ] --구독--> [FastAPI] --저장--> [PostgreSQL]
                                                                              |
                                                                              v
                                                                         [ui 대시보드] (REST API 조회/제어)
```

## 디렉터리 구조

```
scada-capstone/
├── gateway/        # 엣지 디바이스: Modbus 센서 읽기 → MQTT 발행
├── server/         # 클라우드 백엔드 (FastAPI + RabbitMQ(MQTT) + PostgreSQL, Docker Compose)
├── ui/             # 웹 대시보드 (정적 HTML/JS)
├── terraform/      # GCP 인프라 IaC (GCE VM 프로비저닝)
├── db_api/         # (예정) 별도 DB API - 현재 비어 있음
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
`main.py` 상단의 `CLOUD_IP`, `SENSOR_ID` 등을 환경에 맞게 수정하세요.

## 인프라 / CI-CD

- **Terraform**: `terraform/` 에서 GCP VM을 프로비저닝합니다.
- **GitHub Actions** (`.github/workflows/deploy.yml`): `main` 브랜치에 push되면 SSH로 GCP VM에 접속해 `git pull` 후 `server`, `ui`의 Docker Compose를 재빌드/재기동합니다.

## API 요약 (FastAPI)

| Method | Endpoint | 설명 |
|---|---|---|
| GET | `/sensors/{slave_id}/data` | 최신 센서 데이터 조회 |
| GET | `/sensors/{slave_id}/history` | 센서 이력 조회 |
| POST | `/control/relay/{slave_id}` | 릴레이 제어 명령 전송 |
| GET | `/control/relay/{slave_id}/logs` | 릴레이 제어 로그 조회 |
