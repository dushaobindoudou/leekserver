#!/bin/sh

# start mysql
sh /usr/mysql-app/startup.sh

# start redis-server
redis-server /etc/redis/redis.conf --daemonize yes

# 启动api 服务
cd /usr/app/react-native-tinker-node-api-demo/
pm2 start index.js


cd /usr/app/noah-system/

# 初始化数据库
yarn run mysql:init

# 启动noah-system服务
yarn run docker:reload




