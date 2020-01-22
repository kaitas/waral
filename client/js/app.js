//即時関数による初期化
(function init(){

	//worker側に渡すオブジェクトを作成
	post_data = {};

	//Node.jsサーバの接続先
	socket = io.connect('http://wp.shirai.la:3001');

	//マルチスレッドのためのworkerを作成	
	worker = new Worker("js/worker.js");

	//動画ID
	video_id = 'hogehoge';

	//動画
	count_sum = 0;

})();

//Node.jsサーバーに接続した際の処理
socket.on('connect', function(){

	//devicemotionイベントが使用できるブラウザかどうかを判定（ios/sarari,Android/Firefoxのみ対応）
	if ('ondevicemotion' in window){

		//加速度センサ取得開始
		motion_on();

		//デバック用
		document.getElementById("info").innerHTML = "接続";

	}else{
		document.getElementById("info").innerHTML = "非対応ブラウザです";
	}
});

/* devicemotionイベントの動作管理 */
//ON
function motion_on(){
	window.addEventListener("devicemotion", deviceMotion);	
}

//OFF
function motion_off(){
	window.removeEventListener("devicemotion", deviceMotion);
}

//worker側からデータを受け取るイベントハンドラ
worker.onmessage = function(event){

	//笑い回数を増やす
	count_sum++;

	//サーバー側にAmag値と動画再生時間を送る
	socket.json.emit('laugh', {
		videoid: video_id,
		playtime: "10",
		amag: event.data["amag"],
		date: event.data["time"]
	});

};

//加速度センサ値の取得
function deviceMotion(e){

	//DeviceMotionEvent.interval(ミリ秒単位の間隔を返す)
	//document.getElementById("interval").innerHTML = "interval: " + e.interval;

	//時刻データの作成
	var d = new Date();

	var date = d.getFullYear() + "-" + d.getMonth() + 1 + "-" + d.getDate() + " " + d.getHours() + ":"
	 + d.getMinutes() + ":" + d.getSeconds() + ":" + d.getMilliseconds(); 

	//worker側に渡すオブジェクトを作成
	post_data = {x:e.acceleration.x, y:e.acceleration.y, z:e.acceleration.z, time:date};

	//document.getElementById("acc").innerHTML = "acc: " + "計測中";

	//worker側にオブジェクトpost_dataを渡す
	worker.postMessage(post_data);

	//オブジェクトのプロパティ等を削除する
	delete post_data.x;
	delete post_data.y;
	delete post_data.z;
	delete date;
}