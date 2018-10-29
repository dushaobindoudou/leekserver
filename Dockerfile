# Leek Server
#
# VERSION               1.0.8

# 基于哪个镜像进行构建
FROM node:10-alpine

# 添加参数
ARG TAG

# 作者
LABEL Author="rrdfe"

# 描述
LABEL Description="noah system is used for hot update of react native"

# 修改apk镜像 为中科大地址
RUN echo -e "http://mirrors.ustc.edu.cn/alpine/v3.8/main\nhttp://mirrors.ustc.edu.cn/alpine/v3.8/community" > /etc/apk/repositories

# 添加git 服务
RUN apk --update add git openssh && \
    rm -rf /var/lib/apt/lists/* && \
    rm /var/cache/apk/*

# 安装python 2
# ensure local python is preferred over distribution python
ENV PATH /usr/local/bin:$PATH

# http://bugs.python.org/issue19846
# > At the moment, setting "LANG=C" on a Linux system *fundamentally breaks Python 3*, and that's not OK.
ENV LANG C.UTF-8
# https://github.com/docker-library/python/issues/147
ENV PYTHONIOENCODING UTF-8

# install ca-certificates so that HTTPS works consistently
# other runtime dependencies for Python are installed later
RUN apk add --no-cache ca-certificates

ENV GPG_KEY C01E1CAD5EA2C4F0B8E3571504C367C218ADD4FF
ENV PYTHON_VERSION 2.7.15

RUN set -ex \
	&& apk add --no-cache --virtual .fetch-deps \
		gnupg \
		tar \
		xz \
	\
	&& wget -O python.tar.xz "https://www.python.org/ftp/python/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz" \
	&& wget -O python.tar.xz.asc "https://www.python.org/ftp/python/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz.asc" \
	&& export GNUPGHOME="$(mktemp -d)" \
	&& gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$GPG_KEY" \
	&& gpg --batch --verify python.tar.xz.asc python.tar.xz \
	&& { command -v gpgconf > /dev/null && gpgconf --kill all || :; } \
	&& rm -rf "$GNUPGHOME" python.tar.xz.asc \
	&& mkdir -p /usr/src/python \
	&& tar -xJC /usr/src/python --strip-components=1 -f python.tar.xz \
	&& rm python.tar.xz \
	\
	&& apk add --no-cache --virtual .build-deps  \
		bzip2-dev \
		coreutils \
		dpkg-dev dpkg \
		findutils \
		gcc \
		gdbm-dev \
		libc-dev \
		libnsl-dev \
		libressl-dev \
		libtirpc-dev \
		linux-headers \
		make \
		ncurses-dev \
		pax-utils \
		readline-dev \
		sqlite-dev \
		tcl-dev \
		tk \
		tk-dev \
		zlib-dev \
# add build deps before removing fetch deps in case there's overlap
	&& apk del .fetch-deps \
	\
	&& cd /usr/src/python \
	&& gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" \
	&& ./configure \
		--build="$gnuArch" \
		--enable-shared \
		--enable-unicode=ucs4 \
	&& make -j "$(nproc)" \
# set thread stack size to 1MB so we don't segfault before we hit sys.getrecursionlimit()
# https://github.com/alpinelinux/aports/commit/2026e1259422d4e0cf92391ca2d3844356c649d0
		EXTRA_CFLAGS="-DTHREAD_STACK_SIZE=0x100000" \
	&& make install \
	\
	&& find /usr/local -type f -executable -not \( -name '*tkinter*' \) -exec scanelf --needed --nobanner --format '%n#p' '{}' ';' \
		| tr ',' '\n' \
		| sort -u \
		| awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
		| xargs -rt apk add --no-cache --virtual .python-rundeps \
	&& apk del .build-deps \
	\
	&& find /usr/local -depth \
		\( \
			\( -type d -a \( -name test -o -name tests \) \) \
			-o \
			\( -type f -a \( -name '*.pyc' -o -name '*.pyo' \) \) \
		\) -exec rm -rf '{}' + \
	&& rm -rf /usr/src/python \
	\
	&& python2 --version

# if this is called "PIP_VERSION", pip explodes with "ValueError: invalid truth value '<VERSION>'"
ENV PYTHON_PIP_VERSION 18.1

RUN set -ex; \
	\
	wget -O get-pip.py 'https://bootstrap.pypa.io/get-pip.py'; \
	\
	python get-pip.py \
		--disable-pip-version-check \
		--no-cache-dir \
		"pip==$PYTHON_PIP_VERSION" \
	; \
	pip --version; \
	\
	find /usr/local -depth \
		\( \
			\( -type d -a \( -name test -o -name tests \) \) \
			-o \
			\( -type f -a \( -name '*.pyc' -o -name '*.pyo' \) \) \
		\) -exec rm -rf '{}' +; \
	rm -f get-pip.py

# CMD ["python2"]

# 安装并初始化mysql
RUN mkdir -p /usr/mysql-app
VOLUME /usr/mysql-app
COPY startup.sh /usr/mysql-app/startup.sh
RUN apk add --update mysql mysql-client && rm -f /var/cache/apk/*
COPY my.cnf /etc/mysql/my.cnf

# 安装初始化redis
# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN addgroup -S redis && adduser -S -G redis redis

RUN apk add --no-cache \
# grab su-exec for easy step-down from root
		'su-exec>=0.2' \
# add tzdata for https://github.com/docker-library/redis/issues/138
		tzdata

ENV REDIS_VERSION 4.0.11
ENV REDIS_DOWNLOAD_URL http://download.redis.io/releases/redis-4.0.11.tar.gz
ENV REDIS_DOWNLOAD_SHA fc53e73ae7586bcdacb4b63875d1ff04f68c5474c1ddeda78f00e5ae2eed1bbb

# for redis-sentinel see: http://redis.io/topics/sentinel
RUN set -ex; \
	\
	apk add --no-cache --virtual .build-deps \
		coreutils \
		gcc \
		jemalloc-dev \
		linux-headers \
		make \
		musl-dev \
	; \
	\
	wget -O redis.tar.gz "$REDIS_DOWNLOAD_URL"; \
	echo "$REDIS_DOWNLOAD_SHA *redis.tar.gz" | sha256sum -c -; \
	mkdir -p /usr/src/redis; \
	tar -xzf redis.tar.gz -C /usr/src/redis --strip-components=1; \
	rm redis.tar.gz; \
	\
# disable Redis protected mode [1] as it is unnecessary in context of Docker
# (ports are not automatically exposed when running inside Docker, but rather explicitly by specifying -p / -P)
# [1]: https://github.com/antirez/redis/commit/edd4d555df57dc84265fdfb4ef59a4678832f6da
	grep -q '^#define CONFIG_DEFAULT_PROTECTED_MODE 1$' /usr/src/redis/src/server.h; \
	sed -ri 's!^(#define CONFIG_DEFAULT_PROTECTED_MODE) 1$!\1 0!' /usr/src/redis/src/server.h; \
	grep -q '^#define CONFIG_DEFAULT_PROTECTED_MODE 0$' /usr/src/redis/src/server.h; \
# for future reference, we modify this directly in the source instead of just supplying a default configuration flag because apparently "if you specify any argument to redis-server, [it assumes] you are going to specify everything"
# see also https://github.com/docker-library/redis/issues/4#issuecomment-50780840
# (more exactly, this makes sure the default behavior of "save on SIGTERM" stays functional by default)
	\
	make -C /usr/src/redis -j "$(nproc)"; \
	make -C /usr/src/redis install; \
	\
	rm -r /usr/src/redis; \
	\
	runDeps="$( \
		scanelf --needed --nobanner --format '%n#p' --recursive /usr/local \
			| tr ',' '\n' \
			| sort -u \
			| awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
	)"; \
	apk add --virtual .redis-rundeps $runDeps; \
	apk del .build-deps; \
	\
	redis-server --version

RUN mkdir /data && chown redis:redis /data
VOLUME /data
WORKDIR /data

COPY redis.conf /etc/redis/redis.conf 


# 设置环境变量
ENV NODE_ENV production

# 复制启动app脚本
COPY start-noah.sh /usr/local/bin/

RUN mkdir -p ~/.ssh/
# 复制ssh key
# COPY id_rsa.pub ~/.ssh/
# 临时添加脚本用来调试
ADD id_rsa.pub /root/.ssh/id_rsa.pub

# 创建工作目录
RUN mkdir -p /usr/app

# 设置工作目录
WORKDIR /usr/app/

# 测试代码
# COPY index.js /usr/app/
# COPY package.json /usr/app/

# 添加对make的支持
RUN apk add --update make
# 添加G++编译器
RUN apk add --update g++
# 添加 bash
RUN apk add --update bash

# RUN git clone https://github.com/rrd-fe/noah-system.git

# 设置工作目录
# WORKDIR /usr/app/noah-system

# 切换到最新的tag代码
# RUN if [ "x$TAG" = "x" ]; then git checkout -b $(git describe --abbrev=0 --tags); \
#    else git checkout $TAG; fi


# 安装yarn global
RUN npm config set registry https://registry.npm.taobao.org 
RUN npm install -g yarn
RUN npm install -g pm2@latest

# node-sass 需要额外的权限，根据npm官方推荐的方式改写
RUN mkdir ~/.npm-global
RUN npm config set prefix '~/.npm-global'
# RUN export PATH=~/.npm-global/bin:$PATH
ENV PATH ~/.npm-global/bin:$PATH

# 安装node-sass的时候需要读写权限，建议leek-cli放到dev依赖里面  可以使用 RUN chown -R $(whoami) /usr/local/lib/node_modules 修改权限
RUN npm install -g leek-cli --unsafe-perm --registry https://registry.npmjs.org/ --sass-binary-site=http://npm.taobao.org/mirrors/node-sass

# 重新ln文件为全局可以访问
# RUN ln -s ~/.npm-global/bin/leek /usr/local/bin/leek

# 安装部署 noah system
RUN git clone https://github.com/rrd-fe/noah-system.git 

# 设置工作目录
WORKDIR /usr/app/noah-system

# 运行安装依赖包
RUN yarn install

# 创建noah日志目录
RUN mkdir -p /usr/app/noah-log/pm2log

# RUN yarn run build
RUN yarn run docker:deploy

# 安装部署react-native-tinker-node-api-demo

WORKDIR /usr/app

RUN git clone https://github.com/rrd-fe/react-native-tinker-node-api-demo.git

WORKDIR /usr/app/react-native-tinker-node-api-demo

RUN yarn install


# 测试代码
# RUN mkdir -p /usr/app/test
# WORKDIR /usr/app/test
# COPY index.js /usr/app/test
# COPY package.json /usr/app/test
# RUN yarn install


# 对外暴露端口
EXPOSE 9030
EXPOSE 3000
EXPOSE 3306

# 启动服务
ENTRYPOINT ["/usr/local/bin/start-noah.sh"]

