# Leek Server
#
# VERSION               0.0.1

# 基于哪个镜像进行构建
FROM node:10-alpine

ARG TAG

# 作者
LABEL Author="dushaobin@rrdfe"

# 描述
LABEL Description="Leek server for rrd react native hot update"

# 对外暴露端口
EXPOSE 3002

# 设置环境变量
ENV NODE_ENV production

# 添加git 服务
RUN apk --update add git openssh && \
    rm -rf /var/lib/apt/lists/* && \
    rm /var/cache/apk/*

# 创建工作目录
RUN mkdir -p /usr/app

# 设置工作目录
WORKDIR /usr/app/

RUN git clone https://github.com/dushaobindoudou/leekserver.git

# 设置工作目录
WORKDIR /usr/app/leekserver

# 切换到最新的tag代码
RUN if [ "x$TAG" = "x" ]; then git checkout -b $(git describe --abbrev=0 --tags); \
    else git checkout $TAG; fi

# 运行安装依赖包
RUN yarn

# 启动服务
ENTRYPOINT [ "npm", "start" ]




