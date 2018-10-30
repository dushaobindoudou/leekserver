
# noah system for docker

noah system 的 docker安装版本

## 项目结构

Dockerfile 文件放在 项目的根目录

---- package.json     
---- Dockerfile        
---- index.js （测试脚本）     
---- my.cnf mysql配置文件     
---- redis.conf redis配置文件      
---- docker-entrypoint.sh （redis的启动脚本，暂时用不到）   
---- startup.sh mysql的启动脚本可以根据需求进行修改

## 说明

当前docker版本会拉去最新的noah-system代码进行构建运行，
正式发布的时候需要指定当前代码的tag 号
原因：后续版本的基础环境变化，需要更新docker image

集成了 mysql 和 redis 并且自启动。redis.conf 是redis的配置文件， my.cnf 是mysql的配置文件
默认安装了，python、make、bash、gcc、g++包

start-noah.sh 是启动脚本，可以根据需求，来修改这个文件


## Dockerfile 配置流程

1. 基于 node:10-alpine 进行构建

2. 创建项目 根目录 /usr/app

3. 拉取指定 tag 的 代码 到 /usr/app

4. 切换运行的目录到 /usr/app/noah-system

5. 运行 yarn install 进行安装

6. 导出 9030 端口 (noah system 的默认端口）

5. 设置 服务启动命令 ENTRYPOINT ["${path}/start-noah.sh"]


## 使用

docker pull rrdfe/leekserver:noahwdemo3    (待定)      
docker pull dushaobin/leekserver:noahwdemo3   (待定)      

启动docker

docker run -d  -p 3000:3000 -p 9030:9030 -p 3306:3306 -v ~/packages:/usr/app/packages dushaobin/leekserver

启动完成后可以通过 9030端口来访问 noah system服务     
使用 3000端口来访问node demo

## 发布

1. 确定新版本的tag 号

2. 修改Dockerfile 中的 VERSION 版本号

3. 提交最新的修改 Dockerfile

4. 推送 最新的tag 到 github

6. 当新的Tag 被谁送到 github，docker hub 会自动构建 新版本的image


### 注意事项

1. docker build 打包的时候是需要打包到docker内的内容

2. .dockerignore 添加忽略文件

3. docker build -f 指定docker配置文件

4. docker build -t 指定一个tag 创建一个新repository

5. docker 发布前 需要使用 tag 命令 明确要发布的 名称
