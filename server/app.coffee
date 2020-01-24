###
Socketio_server
###

#視聴者（クライアント）クラス
class Client
	id: ''
	server_id: ''
	remote_r: ''
	video: ''
	date: ''

#クライアントの管理クラス
class ClientCollection

	clients: {}

	#サーバーID用の変数
	count = 0

	#クライアントデータの追加（id,server_id,dateを追加）
	add: (client) ->

		#時刻を取得
		datetime = @time()

		#idの追加
		@clients[client.id] = client

		#サーバーID，アクセス日時を追加
		data = @clients[client.id]
		count++
		data.server_id = "#{datetime}"+"#{count}"
		data.date = "#{datetime}"

	#サーバーID作成用の時刻データの作成
	time: ->
		d = new Date()
		year  = d.getFullYear()     # 年（西暦）
		month = d.getMonth() + 1    # 月
		date  = d.getDate()         # 日
		hour  = d.getHours()        # 時
		min   = d.getMinutes()      # 分
		sec   = d.getSeconds()		# 秒
		ms    = d.getMilliseconds() # ミリ秒

		time = "#{year}#{month}#{date}#{hour}#{min}"

		return time

	#クライアントが存在するか確認
	exists: (id) ->
		return @clients[id]?

	#クライアントを取り除く
	remove: (id) ->
		if @exists(id)
				delete @clients[id]

	# クライアントを返す
	get: (id) ->
		if @exists(id)
				return @clients[id]
			else
				return false

	# クライアントの数を返す
	size: ->
		return @names().length

	# クライアント一覧を返す
	names: ->
		list = []
		for own id, client of @clients
			list.push(client.name)
		return list

#現在時刻を取得する関数
gettime = ->
	d = new Date()
	year  = d.getFullYear()     # 年（西暦）
	month = d.getMonth() + 1    # 月
	date  = d.getDate()         # 日
	hour  = d.getHours()        # 時
	min   = d.getMinutes()      # 分
	sec   = d.getSeconds()		# 秒
	ms    = d.getMilliseconds() # ミリ秒

	time = "#{year}-#{month}-#{date} #{hour}:#{min}:#{sec}"

	return time

#サーバークラス
class Server

	#メンバ変数
	io: null		#publicなインスタンス変数
	clients: null
	mysql: null

	database = 
			host: 'yourserver'',
			port: '3306',
			user: 'node',
			password: 'password',
			database: 'waral'

	#コンストラクタ
	constructor: (port) ->

		#インスタンス変数port（public）
		@io = require('socket.io').listen(port)
		@clients = new ClientCollection
		@mysql = require('mysql')

	#サーバー起動メソッド
	run: ->
		@io.sockets.on("connection",(socket) => @connectionEvent(socket))

	#接続時のメソッド
	connectionEvent: (socket) ->
		console.log("connected: %s",socket.id)

		#クライアントを追加する
		client = new Client

		#Node.js側で生成されるIDを格納する
		client.id = socket.id
		@clients.add(client)

		#クライアントにリモートアドレスを追加
		#handshakeオブジェクトからリモートアドレスを取得
		client.remote_r = socket.handshake.address.address

		#現在のクライアント数を表示する
		@counter(socket)

		#ユーザー情報をデータベース側に登録する
		connection1 = @mysql.createConnection(database)

		user_value =
			NODE_ID: client.id
			CLIENT_ID: client.server_id
			REMOTE_ADDRES: client.remote_r 
			USER_AGENT: socket.handshake.headers['user-agent']
			LOGIN: gettime()

		connection1.connect();

		query = connection1.query('INSERT INTO USER_DATA SET ?',user_value, (err, result) ->
			console.log(query.sql)
			console.log(err) if err
			)

		connection1.end();

		#メッセージを送信してきたClientへメッセージを返答（テスト）
		#socket.json.emit('push',{hoge1:"hogehoge", hoge2:"hogehoge2"})

		#クライアント側にクライアントIDを渡す
		#socket.json.emit('server_id',{server_id:client.server_id})

		#デバック：クライアントの状態を確認する	
		console.log('クライアントの状態', @clients.clients)

		###
		各イベントの指定
		・・ここで各イベントの処理を指定する
		###

		#切断時
		socket.on('disconnect', => @disconnectEvent(socket))

		#セッション保持用
		socket.on('allive', => @dummy(socket))

		#動画視聴終了時
		socket.on('video_end',(data) => @EndEvent(socket, data))

		#動画プレーヤー生成後（動画再生開始前）の初期化処理
		socket.on('setup', (data) => @initEvent(socket, data))

		#笑いカウントのイベント
		socket.on('laugh', (data) => @laughEvent(socket, data))

	#切断時
	disconnectEvent: (socket) ->

		client = @clients.get(socket.id)
		console.log("disconnected",client)
		@clients.remove(socket.id)

		#現在のクライアント数を表示する
		@counter(socket)

	#セッション保持用
	dummy: (socket) ->
		console.log ("free")

	#動画視聴終了時
	EndEvent: (socket, data) ->
		#JSON形式で送った方がオーバーヘッドが少ないぶん軽い．
		#（参考）http://d.hatena.ne.jp/Jxck/20110730/1312042603

		console.log("videoid:",data.videoid)
		console.log("laugh:",data.laugh)

		connection2 = @mysql.createConnection(database)

		value1 = connection2.escape(data.laugh)
		value2 = connection2.escape(data.videoid)

		sql2 = "UPDATE VIDEO_DATA SET LAUGH_SUM=LAUGH_SUM + " +value1+ " WHERE VIDEOID =" + value2
		#UPDATE VIDEO_DATA SET LAUGH_SUM=LAUGH_SUM + '100' WHERE VIDEOID ='CuDsXzwFZ6c'

		connection2.connect();
		query2 = connection2.query(sql2,(err,result) ->
			console.log(err) if err
			console.log(query2.sql)
			)
		connection2.end();



	#動画プレーヤー生成後（動画再生開始前）の初期化処理
	initEvent: (socket,data) ->

		#socket.idから該当するクライアントデータを検索	
		client = @clients.get(socket.id)

		#接続先
		connection3 = @mysql.createConnection(database)
		connection4 = @mysql.createConnection(database)

		#動画IDを追加
		client.video = data.videoid

		#Escaping query value
		videoid_sql = connection3.escape(data.videoid)

		#SQL文を作成
		sql3 = "SELECT * FROM VIDEO_DATA WHERE VIDEOID = " + videoid_sql
		sql4 = "UPDATE VIDEO_DATA SET PLAY = PLAY + 1, DATE =" + @mysql.escape(gettime()) + " WHERE VIDEOID =" + videoid_sql

		#サーバー接続（connection3）
		connection3.connect();

		#SQL実行
		query3 = connection3.query(sql3, (err, result1) ->
			console.log(err) if err	
			console.log(query3.sql)

			#値の取得方法（JSONをパースしないで値を取得）
			#（参考）http://programming-10000.hatenadiary.jp/entry/20130807/1375884093
			#console.log("result2: ",result[0].ID)

			#デバック用
			console.log("insert_result: ",result1)
			console.log("length: ", Object.keys(result1).length);

			#resultのあり/なしを判定する
			if Object.keys(result1).length is 0

				#実行結果なし（データベースに追加）
				console.log "result is null"

				#アクセスしたクライアント側に視聴者数と笑い回数を送信する	
				socket.json.emit('video_data',{play:"0", laugh:"0"})

				#insert用のオブジェクトを定義
				insert_value =
					VIDEOID: client.video
					PLAY: 1
					LAUGH_SUM: 0
					DATE: gettime()

				#サーバー接続（connection4）
				connection4.connect();

				#SQL実行(insert文)
				query4 = connection4.query('INSERT INTO VIDEO_DATA SET ?',insert_value, (err, result2) ->
					console.log(query4.sql)
					console.log(err) if err
					)

				#サーバ切断（connection4）
				connection4.end();

			else
				#実行結果あり（データベースを更新）
				console.log "result is set"

				console.log("result1_ID: ",result1[0].ID)
				console.log("result1_PLAY: ",result1[0].PLAY)
				console.log("result1_PLAY: ",result1[0].LAUGH_SUM)				

				#アクセスしたクライアント側に視聴者数と笑い回数を送信する
				socket.json.emit('video_data',{play:result1[0].PLAY, laugh:result1[0].LAUGH_SUM})

				#サーバー接続
				connection4.connect();

				query4 = connection4.query(sql4, (err, result) ->
					console.log(query4.sql)
					console.log(err) if err
					)

				#サーバ切断（connection4）
				connection4.end();

			)

		#サーバ切断
		connection3.end();
	
	#笑いカウントのイベント
	laughEvent: (socket, data) ->

		#接続先
		connection5 = @mysql.createConnection(database)

		#insert用のオブジェクトを定義
		laugh_value =
			NODE_ID: socket.id
			VIDEOID: data.videoid
			PLAYTIME: data.playtime
			AMAG: data.amag
			DATE: data.date

		#サーバー接続
		connection5.connect()

		#SQL文の実行
		query5 = connection5.query('INSERT INTO LAUGH_DATA SET ?',laugh_value, (err, result) ->
			console.log(query5.sql)
			console.log(err) if err
			)

		#サーバ切断
		connection5.end()

	#現在のクライアント数を確認する
	counter: (socket) ->
		names = @clients.size()
		console.log("クライアント数：",names)

###
サーバーの作成と起動
###
server = new Server(3001)
server.run()