#!/bin/bash
set -e

PGDATA="/var/lib/pgsql/data"

mkdir -p "$PGDATA" /var/run/postgresql
chown -R postgres:postgres /var/lib/pgsql /var/run/postgresql
chmod 700 "$PGDATA"
chmod 775 /var/run/postgresql

if [ ! -s "$PGDATA/PG_VERSION" ]; then
    echo "[INFO] PostgreSQL 데이터 디렉토리 초기화 중..."
    su - postgres -c "initdb -D '$PGDATA'"

    # 접속 허용 및 소켓 경로 설정
    echo "host all all 0.0.0.0/0 md5" >> "$PGDATA/pg_hba.conf"
    echo "listen_addresses = '*'" >> "$PGDATA/postgresql.conf"
    echo "unix_socket_directories = '/var/run/postgresql, /tmp'" >> "$PGDATA/postgresql.conf"

    echo "[INFO] 임시 서버 구동 및 초기 세팅 적용 중..."
    su - postgres -c "postgres -D '$PGDATA'" &
    pid="$!"

    # 서버 준비 대기
    until su - postgres -c "pg_isready -h localhost -q"; do
        sleep 1
    done

    # 유저 및 DB 생성
    su - postgres -c "psql -h localhost -c \"CREATE USER service_user WITH PASSWORD 'servicepassword';\""
    su - postgres -c "psql -h localhost -c \"CREATE DATABASE secondhand_db OWNER service_user;\""
    su - postgres -c "psql -h localhost -c \"GRANT ALL PRIVILEGES ON DATABASE secondhand_db TO service_user;\""

    if [ -f /docker-entrypoint-initdb.d/init.sql ]; then
        echo "[INFO] init.sql 실행 중..."
        su - postgres -c "psql -h localhost -d secondhand_db -f /docker-entrypoint-initdb.d/init.sql"
        su - postgres -c "psql -h localhost -d secondhand_db -c \"GRANT ALL ON ALL TABLES IN SCHEMA public TO service_user; GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO service_user;\""
    fi

    # 시그널 종료 시 exit 130으로 멈추지 않도록 || true 처리
    kill -INT "$pid"
    wait "$pid" 2>/dev/null || true
    echo "[INFO] 초기화 완료."
fi

# 메인 PostgreSQL 포그라운드 실행
exec su - postgres -c "postgres -D '$PGDATA'"
