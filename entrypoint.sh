#!/bin/bash
set -e

# 데이터 디렉토리가 비어있으면 초기화 수행
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "[INFO] MariaDB 데이터 디렉토리 초기화 중..."
    mysql_install_db --user=mysql --datadir=/var/lib/mysql > /dev/null

    echo "[INFO] 임시 서버 구동 및 초기 SQL 적용 중..."
    mysqld_safe --datadir=/var/lib/mysql --skip-networking &
    pid="$!"

    # 서버 준비 대기
    until mysqladmin ping --silent; do
        sleep 1
    done

    # root 비밀번호 설정 및 init.sql 실행
    mysql -u root <<-EOSQL
        ALTER USER 'root'@'localhost' IDENTIFIED BY 'rootpassword';
EOSQL

    if [ -f /docker-entrypoint-initdb.d/init.sql ]; then
        mysql -u root -prootpassword < /docker-entrypoint-initdb.d/init.sql
    fi

    # 임시 서버 정상 종료
    mysqladmin -u root -prootpassword shutdown
    wait "$pid"
    echo "[INFO] 초기화 완료."
fi

# 메인 DB 프로세스 foreground 실행
exec mysqld_safe --datadir=/var/lib/mysql
