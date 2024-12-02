FROM alpine:3.20.3

WORKDIR /usr/src

# 拷贝 MySQL 源码
COPY mysql-5.7.44.tar.gz ./
RUN tar zxf mysql-5.7.44.tar.gz 

# 拷贝docker自运行脚本
COPY docker-entrypoint.sh /usr/local/bin/

# 设置代理环境变量
ENV HTTP_PROXY=http://192.168.10.231:7777
ENV HTTPS_PROXY=http://192.168.10.231:7777
ENV NO_PROXY=localhost,127.0.0.1

# 创建用户组和用户
RUN set -eux; \
    addgroup -S mysql && adduser -S mysql -G mysql

# add gosu for easy step-down from root
# https://github.com/tianon/gosu/releases

ENV GOSU_VERSION 1.16

# 安装构建依赖
RUN set -eux; \
    sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories; \
    apk update; \
    apk add --no-cache \
    curl \
    gpg \
    build-base \
    cmake \
    ncurses-dev \
    openssl-dev \
    bison \
    libaio-dev \
    libtirpc-dev \
    rpcgen \
    bash \
    mysql-client \
    tzdata \
    openssl \
    coreutils

RUN set -eux; \
    # TODO find a better userspace architecture detection method than querying the kernel
    arch="$(uname -m)"; \
    case "$arch" in \
    aarch64) gosuArch='arm64' ;; \
    x86_64) gosuArch='amd64' ;; \
    *) echo >&2 "error: unsupported architecture: '$arch'"; exit 1 ;; \
    esac; \
    curl -fL -o /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$gosuArch"; \
    chmod +x /usr/local/bin/gosu; \
    gosu --version; \
    gosu nobody true

WORKDIR /usr/src/mysql-5.7.44

# 编译 MySQL
RUN cmake . -DDOWNLOAD_BOOST=1 -DWITH_BOOST=/usr/local/boost && \
    make && \
    make install


# FROM menzai/mysql-5.7-alpine-tmp-gosu:v1

RUN set -eux; \
    # https://github.com/docker-library/mysql/pull/680#issuecomment-636121520
    mkdir /etc/mysql; \
    cp support-files/my-default.cnf /etc/mysql/my.cnf; \
    # grep -F 'socket=/var/lib/mysql/mysql.sock' /etc/mysql/my.cnf; \
    sed -i 's!^socket=.*!socket=/var/run/mysqld/mysqld.sock!' /etc/mysql/my.cnf; \
    sed -i '$a\log-error=/var/log/mysql/error.log' /etc/mysql/my.cnf; \
    # grep -F 'socket=/var/run/mysqld/mysqld.sock' /etc/mysql/my.cnf; \
    { echo '[client]'; echo 'socket=/var/run/mysqld/mysqld.sock'; } >> /etc/mysql/my.cnf; \
    \
    # make sure users dumping files in "/etc/mysql/conf.d" still works
    # ! grep -F '!includedir' /etc/mysql/my.cnf; \
    { echo; echo '!includedir /etc/mysql/conf.d/'; } >> /etc/mysql/my.cnf; \
    mkdir -p /etc/mysql/conf.d; \
    # 5.7 Debian-based images also included "/etc/mysql/mysql.conf.d" so let's include it too
    { echo '!includedir /etc/mysql/mysql.conf.d/'; } >> /etc/mysql/my.cnf; \
    mkdir -p /etc/mysql/mysql.conf.d; \
    \
    # comment out a few problematic configuration values
    find /etc/mysql/my.cnf /etc/mysql/ -name '*.cnf' -print0 \
    | xargs -0 grep -lZE '^(bind-address|log)' \
    | xargs -rt -0 sed -Ei 's/^(bind-address|log)/#&/'; \
    \
    # ensure these directories exist and have useful permissions
    # the rpm package has different opinions on the mode of `/var/run/mysqld`, so this needs to be after install
    mkdir -p /var/lib/mysql /var/run/mysqld /var/log/mysql; \
    chown mysql:mysql /var/lib/mysql /var/run/mysqld /usr/local/bin/docker-entrypoint.sh /etc/mysql /var/log/mysql; \
    # ensure that /var/run/mysqld (used for socket and lock files) is writable regardless of the UID our mysqld instance ends up having at runtime
    chmod 1777 /var/lib/mysql /var/run/mysqld; \
    \
    mkdir /docker-entrypoint-initdb.d; \
    \
    ln -s /usr/local/mysql/bin/mysqld /usr/local/bin/mysqld; \
    ln -s /usr/local/mysql/bin/mysql /usr/local/bin/mysql; \
    ln -s /usr/local/mysql/bin/mysql_tzinfo_to_sql /usr/local/bin/mysql_tzinfo_to_sql; \
    mysqld --version; \
    mysql --version;

# 清理构建依赖
# RUN apk del build-base cmake ncurses-dev openssl-dev bison git libaio-dev

VOLUME /var/lib/mysql

ENTRYPOINT ["docker-entrypoint.sh"]

# 暴露端口
EXPOSE 3306

# 启动 MySQL
CMD ["mysqld"]