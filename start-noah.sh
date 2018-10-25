#!/bin/sh

# start mysql
sh /usr/mysql-app/startup.sh

# start redis-server
redis-server /etc/redis/redis.conf --daemonize yes

# 创建数据库脚本
# mysql -uroot -e "create database noah_system;"

# 启动api 服务
cd /usr/app/react-native-tinker-node-api-demo/
pm2 start index.js


cd /usr/app/noah-system/

# 初始化数据库
yarn run mysql:init

# 开始部署docker
# yarn run docker:deploy

# 启动noah-system服务
yarn run docker:reload

# 启动api 服务
# cd /usr/app/react-native-tinker-node-api-demo/
# yarn start



