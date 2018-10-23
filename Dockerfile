# Leek Server
#
# VERSION               1.0.8

# 基于哪个镜像进行构建
FROM node:10-alpine

# 添加参数
ARG TAG

# 作者
LABEL Author="dushaobin@rrdfe"

# 描述
LABEL Description="Leek server for rrd react native hot update"

# 修改apk镜像 为中科大地址
RUN echo -e "http://mirrors.ustc.edu.cn/alpine/v3.8/main\nhttp://mirrors.ustc.edu.cn/alpine/v3.8/community" > /etc/apk/repositories

# 添加git 服务
RUN apk --update add git openssh && \
    rm -rf /var/lib/apt/lists/* && \
    rm /var/cache/apk/*

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
COPY startLeekServer.sh /usr/local/bin/

# 创建工作目录
RUN mkdir -p /usr/app

# 设置工作目录
WORKDIR /usr/app/

# 测试代码
COPY index.js /usr/app/
COPY package.json /usr/app/

# RUN git clone https://github.com/dushaobindoudou/noah-system.git

# 设置工作目录
# WORKDIR /usr/app/noah-system

# 切换到最新的tag代码
# RUN if [ "x$TAG" = "x" ]; then git checkout -b $(git describe --abbrev=0 --tags); \
#    else git checkout $TAG; fi

# 安装yarn global
RUN npm config set registry https://registry.npm.taobao.org 
RUN npm install -g yarn
RUN npm install -g pm2@latest

# 运行安装依赖包
RUN yarn install
RUN yarn run build

# 对外暴露端口
EXPOSE 9030

# 启动服务
ENTRYPOINT ["/usr/local/bin/startLeekServer.sh"]

