# ローカル変数（ローパスフィルタ） 

#一つ前のローパス値を参照する必要があるので，グルーバルで定義します．
low_x = 0
low_y = 0
low_z = 0
count = 0
worker_data = {}

self.onmessage = (event) ->

	 #送られてきたオブジェクトをworker側のオブジェクトに格納させる
	 post_data = event.data

	 #取得した加速度値をm/s秒から[G]に変換します
	 #m/s秒 / 9.80665
	 temp_x = post_data["x"] / 9.8
	 temp_y = post_data["y"] / 9.8
	 temp_z = post_data["z"] / 9.8

	 #ローパスフィルタの算出
	 low_x = temp_x * 0.1 + low_x * (1.0 - 0.1)
	 low_y = temp_y * 0.1 + low_y * (1.0 - 0.1)
	 low_z = temp_z * 0.1 + low_z * (1.0 - 0.1)

	 #ハイパスフィルタの算出
	 high_x = temp_x - low_x
	 high_y = temp_y - low_y
	 high_z = temp_z - low_z

	 #Amag値の算出
	 mag = Math.sqrt(high_x * high_x + high_y * high_y + high_z * high_z)

	 #オブジェクトの作成（amg:Amag値，time:再生時間）
	 worker_data =
	 	amag: mag
	 	time: post_data["time"]
	 	currenttime: post_data["currenttime"]

	 #Amag判定
	 #演算結果をメインスレッド側に渡す
	 self.postMessage worker_data if mag >= 0.2