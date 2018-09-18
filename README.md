
# leekserver for docker

leek server的 docker版本的实现

## 项目结构

Dockerfile 文件放在 项目的根目录

---- package.json     
---- Dockerfile     
---- node_modules     
---- src     

## 说明
当前的Dockerfile 可以通过参数传递要构建的leekserver版本：    
`docker build --build_arg TAG=v1.0.3`    
如果没有传递参数默认拉取最新的 tag 进行构建，我们每个版本的image都是类似的，实际的项目内容根据传入的版本来确定     

docker hub的tag 只是表明当前的代码更新到哪个版本，并没有太大的意义

如果需要 docker hub 的tag 拉取的是固定的版本代码 需要修改 TAG 参数为指定的版本 例如：    
v1.0.2的版本 需要把 TAG=v1.0.2 就可以了，根据实际的需要来进行相关的配置


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

