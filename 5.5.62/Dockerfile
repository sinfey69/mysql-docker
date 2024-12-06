FROM debian:stretch-slim AS builder

# 设置代理环境变量
ENV HTTP_PROXY=http://192.168.10.231:7777
ENV HTTPS_PROXY=http://192.168.10.231:7777
ENV NO_PROXY=localhost,127.0.0.1

# 更改更新源
RUN echo "deb http://snapshot.debian.org/archive/debian/20210701T000000Z/ stretch main" > /etc/apt/sources.list && \
	echo "deb http://snapshot.debian.org/archive/debian/20210701T000000Z/ stretch-updates main" >> /etc/apt/sources.list && \
	echo "deb http://snapshot.debian.org/archive/debian-security/20210701T000000Z/ stretch/updates main" >> /etc/apt/sources.list

# 1、不对依赖包做过期检查 2、apt配置文件以使用代理
RUN echo 'Acquire::Check-Valid-Until "false";' > /etc/apt/apt.conf.d/99archive && \
	echo 'Acquire::http::Proxy "http://192.168.10.231:7777";' >> /etc/apt/apt.conf.d/99archive && \
	echo 'Acquire::https::Proxy "http://192.168.10.231:7777";' >> /etc/apt/apt.conf.d/99archive

RUN set -x; \
	apt-get update && apt-get install -y --no-install-recommends --allow-unauthenticated \
	build-essential \
	libncurses5-dev \
	cmake \
	git \
	bison \
	&& rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src
# 拷贝 MySQL 源码
COPY mysql-5.5.62.tar.gz ./
RUN tar zxf mysql-5.5.62.tar.gz 
WORKDIR /usr/src/mysql-5.5.62
# 解决新版gcc编译不兼容旧版gcc4.8的问题
COPY client_plugin.c sql-common/

# 编译 MySQL
RUN cmake . && \
	make && \
	make install

FROM debian:stretch-slim

# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN groupadd -r mysql && useradd -r -g mysql mysql

# add gosu for easy step-down from root
ENV GOSU_VERSION=1.7
COPY gosu-1.7-arm64 /usr/local/bin/gosu
RUN chmod +x /usr/local/bin/gosu \
	&& gosu nobody true

# 拷贝docker启动执行脚本
COPY docker-entrypoint.sh /usr/local/bin/
RUN mkdir /docker-entrypoint-initdb.d

ENV MYSQL_MAJOR=5.5
ENV MYSQL_VERSION=5.5.62

RUN mkdir -p /usr/local/mysql/
COPY --from=builder /usr/local/mysql /usr/local/mysql

ENV PATH=$PATH:/usr/local/mysql/bin:/usr/local/mysql/scripts


# 更改更新源
RUN echo "deb http://snapshot.debian.org/archive/debian/20210701T000000Z/ stretch main" > /etc/apt/sources.list && \
	echo "deb http://snapshot.debian.org/archive/debian/20210701T000000Z/ stretch-updates main" >> /etc/apt/sources.list && \
	echo "deb http://snapshot.debian.org/archive/debian-security/20210701T000000Z/ stretch/updates main" >> /etc/apt/sources.list

# 1、不对依赖包做过期检查 2、apt配置文件以使用代理
RUN echo 'Acquire::Check-Valid-Until "false";' > /etc/apt/apt.conf.d/99archive && \
	echo 'Acquire::http::Proxy "http://192.168.10.231:7777";' >> /etc/apt/apt.conf.d/99archive && \
	echo 'Acquire::https::Proxy "http://192.168.10.231:7777";' >> /etc/apt/apt.conf.d/99archive

RUN set -x; \
	apt-get update && apt-get install -y --no-install-recommends --allow-unauthenticated \
	# for MYSQL_RANDOM_ROOT_PASSWORD
	pwgen \
	# FATAL ERROR: please install the following Perl modules before executing /usr/local/mysql/scripts/mysql_install_db:
	# File::Basename
	# File::Copy
	# Sys::Hostname
	# Data::Dumper
	# perl \
	# mysqld: error while loading shared libraries: libaio.so.1: cannot open shared object file: No such file or directory
	libaio1 \
	# mysql: error while loading shared libraries: libncurses.so.5: cannot open shared object file: No such file or directory
	libncurses5 

# replicate some of the way the APT package configuration works
# this is only for 5.5 since it doesn't have an APT repo, and will go away when 5.5 does
RUN mkdir -p /etc/mysql/conf.d \
	&& { \
	echo '[mysqld]'; \
	echo 'skip-host-cache'; \
	echo 'skip-name-resolve'; \
	echo 'datadir = /var/lib/mysql'; \
	echo '!includedir /etc/mysql/conf.d/'; \
	} > /etc/mysql/my.cnf

RUN mkdir -p /var/lib/mysql /var/run/mysqld \
	&& chown -R mysql:mysql /var/lib/mysql /var/run/mysqld /usr/local/bin/docker-entrypoint.sh \
	# ensure that /var/run/mysqld (used for socket and lock files) is writable regardless of the UID our mysqld instance ends up having at runtime
	&& chmod 777 /var/run/mysqld

VOLUME /var/lib/mysql

ENTRYPOINT ["docker-entrypoint.sh"]

EXPOSE 3306
CMD ["mysqld"]
