#!/bin/bash

# Docker 설치
apt-get update
apt-get install -y docker.io git
systemctl start docker
systemctl enable docker

# Docker Compose V2 설치
apt-get install -y docker-compose-v2

# 배포용 SSH 키를 임시로 심어두기 (git clone 인증용)
mkdir -p /root/.ssh
cat > /root/.ssh/deploy_key << 'EOF'
__DEPLOY_KEY_PLACEHOLDER__
EOF
chmod 600 /root/.ssh/deploy_key

# GitHub host key 등록 (최초 접속 시 확인 절차 생략용)
ssh-keyscan github.com >> /root/.ssh/known_hosts

# 이 키를 쓰도록 git 설정
export GIT_SSH_COMMAND="ssh -i /root/.ssh/deploy_key"

# 레포 clone
git clone git@github.com:chaeyeon1382-arch/scada-capstone-infra.git /opt/scada-capstone

# 데모용 .env 파일 생성 (테스트 전용 값, 운영 비밀번호 아님)
cat > /opt/scada-capstone/server/.env << 'EOF'
POSTGRES_PASSWORD=demo_test_only
EOF

# 서비스 실행
cd /opt/scada-capstone/server
docker compose up -d --build