
# leekserver for docker

leek server的 docker版本的实现

## 项目结构

Dockerfile 文件放在 项目的根目录

---- package.json     
---- Dockerfile     
---- node_modules     
---- src     

## Dockerfile 配置流程

1. 基于 node:10-alpine 进行构建

2. 创建项目 根目录 /usr/nodejs/app

3. 拉取指定 tag 的 代码 到 /usr/app

4. 切换运行的目录到 /usr/app/leekserver

5. 运行 yarn install 进行安装

6. 导出 3002 端口 （leek server 的默认端口）

5. 设置 服务启动命令 ENTRYPOINT ["npm", "start"]


## 使用

docker pull rrdfe/leekserver    
docker pull dushaobin/leekserver

启动docker

docker run -p 3002:3002 dushaobin/leekserver

启动完成后可以通过 3002端口来访问 leekserver服务

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

