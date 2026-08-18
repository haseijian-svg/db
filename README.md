# 중고 거래 사이트 DB 환경 (Rocky Linux + PostgreSQL)

Rocky Linux 9 기반의 PostgreSQL 도커 환경입니다. 초기 구동 시 `init.sql`의 스키마가 자동으로 적용됩니다.

---

## 1. 이미지 빌드
```bash
docker build -t rocky-postgres:1.0 .
