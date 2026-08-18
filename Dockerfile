FROM mariadb:10.11

# 환경 변수 설정
ENV MARIADB_ROOT_PASSWORD=rootpassword
ENV MARIADB_DATABASE=secondhand_db
ENV MARIADB_USER=service_user
ENV MARIADB_PASSWORD=servicepassword

# 최초 기동 시 자동 실행될 SQL 스크립트 복사
COPY init.sql /docker-entrypoint-initdb.d/

EXPOSE 3306
