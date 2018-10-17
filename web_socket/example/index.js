const WebSocket = require('ws');

const ws = new WebSocket('ws://localhost:4000/logs/core');

ws.on('open', () => {
  console.log('opened');
  ws.send('ping');
});

ws.on('message', (msg) => {
  console.log('message:', msg);
});

ws.on('close', () => {
  console.log('closed');
});

ws.on('error', (err) => {
  console.error(err);
});
