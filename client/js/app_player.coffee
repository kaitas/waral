#1.即時関数による初期化関数
(->
	# URLパラメータから動画IDの取得とiframe player生成
	vars = []
	hash = undefined
	hashes = window.location.href.slice(window.location.href.indexOf("?") + 1).split("&")

	i = 0

	while i < hashes.length
		hash = hashes[i].split("=")
		vars.push hash[0]
		vars[hash[0]] = hash[1]
		i++

	#YouTube動画IDを格納（=グロ-バル変数として利用可能）
	@url = vars

	#iframe Player APIのコードを非同期に読み込み
	tag = document.createElement("script")
	tag.src = "http://www.youtube.com/iframe_api"
	firstScriptTag = document.getElementsByTagName("script")[0]
	firstScriptTag.parentNode.insertBefore tag, firstScriptTag

	#worker側に渡すオブジェクトを作成
	@post_data = {}

	#Node.jsサーバの接続先
	@socket = io.connect("http://wp.shirai.la:3001")

	#マルチスレッドのためのworkerを作成 
	@worker = new Worker("../js/worker.js")

	#笑い回数のカウント用変数
	@count_sum = 0

)()

#2.iframePlayerの準備
onYouTubeIframeAPIReady = ->
  @player = new YT.Player("player", # 動画プレーヤーを埋め込む要素I
		width: "680" # 動画プレーヤーの幅
		height: "480" # 動画プレーヤーの高さ
		videoId: url["video"] # YouTube動画ID
		events:
			onReady: onPlayerReady
			onStateChange: onPlayerStateChange
      )

#3.プレーヤの準備完了時に呼び出される関数
onPlayerReady = (event) ->
	console.log "ready"

#再生終了時に呼び出される関数
onVideoEnd = ->
	console.log "End"

	#サーバー側にAmag値と動画再生時間を送る
	socket.json.emit('video_end', {videoid:url["video"], laugh:count_sum})

	#googleフォーム側に送信するGETメソッド用のデータを作成
	user_data = url["video"] + "_" + socket.socket.transport.sessid

	#アンケートフォームに画面遷移（クライアントIDと動画IDを送信）
	form = "https://docs.google.com/a/shirai.la/forms/d/1L52Uw8lBBxR9XoawCUTbk-PwZRQ5RZ9-Rv_qCOFp23g/viewform?"
	location.href= form+"entry_895125279="+count_sum+"&entry_1765780202="+user_data

#プレーヤの状態変化時に呼び出される関数
onPlayerStateChange = (event) ->
  #状態（PlayerState）遷移の管理
  switch event.data
    
    # 0:再生終了 
    when YT.PlayerState.ENDED
      motion_off()
      onVideoEnd()
    
    # 1:再生中 
    when YT.PlayerState.PLAYING
      motion_on()
    
    # 2:一時停止 
    when YT.PlayerState.PAUSED
      motion_off()
    
    # 3:バッファリング中 
    when YT.PlayerState.BUFFERING
      motion_off()
    
    # 5:頭出し 
    when YT.PlayerState.CUED
      motion_off()


#4.Node.jsサーバー接続時
socket.on "connect", ->
	#サーバー側に動画IDを送信する
	socket.json.emit('setup',{videoid: url["video"]}) 

	#サーバー側から送られてくる視聴回数と笑い回数を取得し，html上に表示
	socket.on "video_data", (data) ->

		#画面上に再生回数と笑い指数を表示させる
		$("#video_data").html "再生:" + data.play + " | " + " 笑い指数: " + data.laugh


#Node.jsサーバー切断時
socket.on "disconnect_client", (data) ->
	$("#debug_view").html "お手数ですが，Webブラウザをリロードしてください"


###
センサ関係
###

#ON
motion_on = ->
	window.addEventListener "devicemotion", deviceMotion

#OFF
motion_off = ->
	window.removeEventListener "devicemotion", deviceMotion

#加速度センサ値の取得
deviceMotion = (e) ->

	#時刻データの作成
	d = new Date()
	date = d.getFullYear() + "-" + d.getMonth() + 1 + "-" + d.getDate() + " " + d.getHours() + ":" + d.getMinutes() + ":"+ d.getSeconds() + ":" + d.getMilliseconds()

	#端末向き（角度）の取得
	#$("#debug_view").html "orientation: " + window.orientation

	#worker側に渡すオブジェクトを作成
	post_data =
		 x: e.acceleration.x
		 y: e.acceleration.y
		 z: e.acceleration.z
		 time: date
		 currenttime: player.getCurrentTime()

	#worker側にオブジェクトpost_dataを渡す
	worker.postMessage post_data


#worker側からデータを受け取るイベントハンドラ
worker.onmessage = (event) ->

	#笑い回数を増やす
	count_sum++

	#サーバー側にAmag値と動画再生時間を送る
	socket.json.emit "laugh",
	　videoid: url["video"]
	　playtime: event.data["currenttime"]
	　amag: event.data["amag"]
	　date: event.data["time"]

	#デバック用
	$("#count_view").html "笑い回数: " + count_sum
	