// Generated by CoffeeScript 1.6.3
/*
Socketio_server用のテストプログラム
*/

var client, socket;

client = require('socket.io-client');

socket = client.connect('http://wp.shirai.la:3001');

socket.on("connect", function() {
  console.log("connect!: ");
  socket.on("push", function(data) {
    console.log("push1: " + data.hoge1);
    return console.log("push2: " + data.hoge2);
  });
  socket.on("server_id", function(data) {
    return console.log("server_id: " + data.server_id);
  });
  return socket.json.emit('video_end', {
    videoid: "7M4oacp9dmI",
    laugh: "100"
  });
});
