FROM rockylinux:9

# PostgreSQL 15 서버 및 모듈 설치
RUN dnf install -y postgresql-server postgresql-contrib && \
    dnf clean all

# 초기화 스크립트 및 SQL 복사
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY init.sql /docker-entrypoint-initdb.d/init.sql

RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 5432

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
