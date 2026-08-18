# CloudeDX DB 환경 (Rocky Linux 9 + PostgreSQL 16)

Rocky Linux 9 기반으로 빌드된 PostgreSQL 16 컨테이너 환경입니다.

---

## 1. 빌드 및 단독 실행
```bash
docker build -t rocky-postgres:16 .

docker run -d \
  --name rocky-pg \
  -p 5432:5432 \
  -v cloudedx_pgdata:/var/lib/pgsql/data \
  rocky-postgres:16
