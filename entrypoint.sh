#!/bin/bash
set -e
PGDATA="/var/lib/pgsql/data"
mkdir -p "$PGDATA" /var/run/postgresql
chown -R postgres:postgres /var/lib/pgsql /var/run/postgresql
chmod 700 "$PGDATA"
chmod 775 /var/run/postgresql

if [ ! -s "$PGDATA/PG_VERSION" ]; then
    echo "[INFO] PostgreSQL 16 데이터 디렉토리 초기화 중..."
    gosu postgres initdb -D "$PGDATA" \
        --auth-local=peer --auth-host=scram-sha-256 \
        --locale=en_US.UTF-8 --encoding=UTF8

    # ---------------------------------------------------------------------
    # 접속 허용 범위: Docker 기본 브릿지 네트워크 대역(172.16.0.0/12)만 허용.
    # 0.0.0.0/0(전체 허용)은 컨테이너 포트가 실수로 외부에 노출됐을 때
    # 그대로 공격 표면이 되므로 쓰지 않는다. 같은 docker-compose 네트워크
    # 안의 migrate/backend/crawler 컨테이너는 이 대역에서 접속하므로
    # 정상 동작하고, 그 외 대역에서 오는 접속은 여기서 차단된다.
    #
    # 참고: db 컨테이너 자기 자신의 초기화용 psql 호출(아래)은 유닉스
    # 소켓(peer 인증)을 쓰므로 이 host 규칙과는 무관하다.
    # ---------------------------------------------------------------------
    echo "host all all 172.16.0.0/12 scram-sha-256" >> "$PGDATA/pg_hba.conf"

    echo "listen_addresses = '*'" >> "$PGDATA/postgresql.conf"
    echo "password_encryption = scram-sha-256" >> "$PGDATA/postgresql.conf"
    echo "unix_socket_directories = '/var/run/postgresql, /tmp'" >> "$PGDATA/postgresql.conf"

    echo "[INFO] 임시 서버 구동 및 계정/DB 세팅 적용 중..."
    gosu postgres postgres -D "$PGDATA" &
    pid="$!"
    # -h localhost 는 TCP 접속을 강제해 scram-sha-256(비밀번호) 인증을 타게
    # 되는데, 아직 postgres 계정에 비밀번호가 없어 실패한다. 유닉스 소켓
    # 경로를 직접 지정하면 --auth-local=peer 규칙을 타서 비밀번호 없이
    # 접속된다 (OS 계정 postgres == DB 롤 postgres 로 매칭).
    SOCKET_DIR="/var/run/postgresql"
    until gosu postgres pg_isready -h "$SOCKET_DIR" -q; do
        sleep 1
    done

    # CloudeDX 전용 유저 및 DB 생성 (cloudedx / cloudedx)
    gosu postgres psql -h "$SOCKET_DIR" -c "CREATE USER cloudedx WITH PASSWORD 'cloudedx';"
    gosu postgres psql -h "$SOCKET_DIR" -c "CREATE DATABASE cloudedx OWNER cloudedx;"
    gosu postgres psql -h "$SOCKET_DIR" -c "GRANT ALL PRIVILEGES ON DATABASE cloudedx TO cloudedx;"

    kill -INT "$pid"
    wait "$pid" 2>/dev/null || true
    echo "[INFO] 초기화 완료."
fi

# gosu로 PID 1을 postgres 프로세스 자체로 넘긴다. su와 달리 gosu는
# SIGTERM을 그대로 자식에게 전달하므로 `docker stop` 시 정상 종료된다
# (su를 썼을 때처럼 10초 대기 후 SIGKILL로 강제 종료되지 않는다).
exec gosu postgres postgres -D "$PGDATA"

