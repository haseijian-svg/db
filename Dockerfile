FROM rockylinux:9

# PostgreSQL 공식 RPM 저장소 및 EPEL 등록 후 PostgreSQL 16 설치.
# gosu는 EPEL/기본 저장소에 RPM으로 배포되지 않아 dnf로 설치할 수 없다.
# 공식 postgres Docker 이미지들도 GitHub 릴리스에서 바이너리를 직접
# 받아 쓰는 방식을 쓰므로 동일하게 처리한다.
# curl은 rockylinux:9 베이스 이미지에 curl-minimal로 이미 포함돼 있어
# 따로 설치하지 않는다 — curl(풀버전)을 추가 설치하면 curl-minimal과
# 같은 명령어를 제공해 충돌한다. curl-minimal만으로 HTTPS 다운로드는 충분하다.
# glibc-langpack-en: 최소 이미지에는 en_US.UTF-8 로케일이 없어 initdb가
# 이 로케일을 못 찾고 실패한다. 한글 데이터(브랜드명 등)를 다루므로
# 인코딩을 UTF8로 명시할 것인데, 그러려면 로케일이 먼저 설치돼 있어야 한다.
RUN dnf -y install epel-release && \
    dnf -y install https://download.postgresql.org/pub/repos/yum/reporpms/EL-9-x86_64/pgdg-redhat-repo-latest.noarch.rpm && \
    dnf -y module disable postgresql && \
    dnf -y install postgresql16-server postgresql16-contrib glibc-langpack-en && \
    dnf clean all

# gosu 바이너리 직접 설치 (x86_64 기준)
ENV GOSU_VERSION=1.17
RUN set -eux; \
    curl -fsSL -o /usr/local/bin/gosu \
      "https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu-amd64"; \
    chmod +x /usr/local/bin/gosu; \
    gosu nobody true

# PostgreSQL 16 바이너리 경로 환경변수 등록 (psql, initdb, pg_isready 등을 바로 사용 가능하도록)
ENV PATH="/usr/pgsql-16/bin:$PATH"

VOLUME ["/var/lib/pgsql/data"]

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 5432

HEALTHCHECK --interval=5s --timeout=5s --retries=5 \
  CMD /usr/pgsql-16/bin/pg_isready -U cloudedx -d cloudedx -h localhost || exit 1

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

