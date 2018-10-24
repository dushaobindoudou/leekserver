#!/bin/sh

# start mysql
sh /usr/mysql-app/startup.sh

# start redis-server
redis-server /etc/redis/redis.conf --daemonize yes

# 初始化数据库
yarn run mysql:init

# 启动服务
yarn run prod

#pm2-runtime pm2.json
#node src/index.js

