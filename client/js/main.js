$( document ).on( "pageinit", "#url", function(event) {
	console.log( "url is pageinit" );

	$(this).on("vclick", "#btn1",function(e){
		var msg = $("#search-url").val();

		//v=で分割し，動画IDを取得する．
		var split_msg = msg.split("v=");

		//分割した配列に動画IDが存在していれば，ページを移動．
		if(split_msg[1]){
			console.log("btn1 is click: "+split_msg[1]);
			//location.href="http://waral.shirai.la/waral/player.html?video="+split_msg[1];
			location.href="http://waral.shirai.la/view/player.html?video="+split_msg[1];
		}else{
			console.log("正しいURLではありません");
		}
	});
});