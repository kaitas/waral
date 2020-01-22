#!/bin/bash
	coffee --compile --bare  app.coffee
	coffee --compile --bare  client.coffee
	
	scp -P 22000 app.js kitada@wp.shirai.la:/home/kitada/socket.io_server
