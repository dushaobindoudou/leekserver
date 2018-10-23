#!/bin/sh

# start mysql
sh /usr/mysql-app/startup.sh

# start redis-server
redis-server /etc/redis/redis.conf --daemonize yes

# 启动服务
yarn run prod

