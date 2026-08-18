cat << 'EOF' > README.md
# 중고 거래 사이트 DB 환경 (Rocky Linux + MariaDB)

## 1. 이미지 빌드
```bash
docker build -t rocky-mariadb:1.0 .
