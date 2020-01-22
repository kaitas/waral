###
Socketio_server用のテストプログラム
###

client = require('socket.io-client');
socket = client.connect('http://wp.shirai.la:3001')

socket.on "connect", ->
	 console.log "connect!: "

	 #サーバーから送られてきたデータを表示する（テスト）
	 socket.on "push", (data) ->
	 	console.log "push1: " + data.hoge1
	 	console.log "push2: " + data.hoge2

	 socket.on "server_id", (data) ->
	 	console.log "server_id: " + data.server_id
	 
	 #laughのテスト
	 #socket.json.emit('laugh', {videoid:"7M4oacp9dmI", playtime:"10", amag:"0.12345", date:"2014-1-1 12:00:00:00"})

	 #EndEventのテスト
	 socket.json.emit('video_end', {videoid:"7M4oacp9dmI", laugh:"100"})

	 #setupのテスト
	 #socket.json.emit('setup',{videoid: "7M4oacp9dmI"})