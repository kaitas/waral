$( document ).on( "pageinit", "#home", function(event) {
	console.log( "home is pageinit" );

	if ('ondevicemotion' in window) {
		//$("#device_check").html("対応ブラウザです");
	}else{
		$("#device_check").html("非対応ブラウザです．動作環境をご確認ください．");
	}
});