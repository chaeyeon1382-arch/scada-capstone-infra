#!/bin/bash

# Docker 설치 (공식 스크립트 - Debian/Ubuntu 모두 호환)
curl -fsSL https://get.docker.com | sh
apt-get install -y git
systemctl start docker
systemctl enable docker

# 배포용 SSH 키를 임시로 심어두기 (git clone 인증용)
mkdir -p /root/.ssh
cat > /root/.ssh/deploy_key << 'EOF'
__DEPLOY_KEY_PLACEHOLDER__
EOF
chmod 600 /root/.ssh/deploy_key

# GitHub host key 등록
ssh-keyscan github.com >> /root/.ssh/known_hosts

# 이 키를 쓰도록 git 설정
export GIT_SSH_COMMAND="ssh -i /root/.ssh/deploy_key"

# 레포 clone
git clone git@github.com:chaeyeon1382-arch/scada-capstone-infra.git /opt/scada-capstone

# 데모용 .env 파일 생성
cat > /opt/scada-capstone/server/.env << 'EOF'
POSTGRES_USER=demo_user
POSTGRES_PASSWORD=demo_test_only
POSTGRES_DB=demo_db
DATABASE_URL=postgresql://demo_user:demo_test_only@postgres:5432/demo_db
RABBITMQ_USER=demo_user
RABBITMQ_PASS=demo_pass
EOF

# 서비스 실행
cd /opt/scada-capstone/server
docker compose up -d --build

# PostgreSQL이 완전히 준비될 시간을 확보 (의존성 순서 문제 방지)
sleep 15
docker restart scada-fastapi