const Koa = require('koa');
const app = new Koa();

app.use(async function(ctx) {
    ctx.body = 'Hello World leek server master/ auto build when push tag';
});

app.listen(3002);

console.log('server is runing on: ', 3002);