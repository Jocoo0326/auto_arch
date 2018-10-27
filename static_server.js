const http = require("http");
const fs = require("fs");
const EventEmitter = require("events");

class RouteEmitter extends EventEmitter {}
const Router = new RouteEmitter();
Router.on('get', (res, data) => {
    fs.readFile(data, 'utf-8', (err, filecontent) => {
	if (err) {
	    Router.emit('err', res, err.toString());
	    return;
	}
	res.statusCode = 200;
	res.setHeader('Content-Type', 'text/plain');
	res.end(filecontent);
    });
});
Router.on('err', (res, desc) => {
    res.statusCode = 404;
    res.end(desc || 'Not found resouce');
});

const host = '0.0.0.0';
const port = 3000;

const server = http.createServer();
server.on('request', (req, res) => {
    const url = req.url;
    const staticRegex = new RegExp(/^\/static\/(.+)/);
    var staticMatchs = staticRegex.exec(url);
    if (staticMatchs != null) {
	Router.emit('get', res, staticMatchs[1]);
    } else {
	Router.emit('err', res);
    }
})

server.listen(port, host, () => {
    console.log(`Server running at http://${host}:${port}`);
});
