# leekserver for docker

leek server的 docker版本的实现

## 项目结构

Dockerfile 文件放在 项目的根目录，docker pull/leek-server 从github拉取项目
然后 根据项目中的 Dockerfile 初始化docker container

---- package.json    
---- Dockerfile    
---- node_modules    
---- src

## Dockerfile 配置流程

1. 基于 node:10-alpine 进行构建

2. 创建项目 根目录 /usr/nodejs/app

3. 拉取指定 tag 的 代码 到 /usr/nodejs/app

4. 切换运行的目录到 /usr/nodejs/app/leekserver

5. 运行 yarn install 进行安装

6. 导出 3002 端口 （leek server 的默认端口）

5. 设置 服务启动命令 ENTRYPOINT ["yarn", "start"]


## 使用

docker pull rrdfe/leekserver

## 发布

1. 确定新版本的tag 号

2. 修改 Dockerfile 拉取的tag 号

3. 发布 新版的 Dockerfile 到 docker hub

4. 提交最新的修改 Dockerfile

5. 推送 最新的tag 到github

todo：发布自动化






