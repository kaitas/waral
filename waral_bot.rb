# -*- encoding: utf-8 -*-
require	'rubygems'
require 'rsruby'
require 'csv'
require 'fileutils'
require 'twitter'
require 'oauth'

#現在の日付データを作成
t = Time.now

#指定フォーマットで文字列を変換
#ファイル保存用の時刻データを作成
strTime = t.strftime("%Y-%m-%d %H:%M:%S")

#Rの操作
r = RSRuby::instance
r.eval_R(<<-RCOMMAND)

library(RMySQL)
dbconnector <- dbConnect(dbDriver("MySQL"),dbname="waral",user="node",password="*password*")
data.tables <- dbGetQuery(dbconnector,"select * from LAUGH_DATA where VIDEOID='n5P5mAZLtO4'")
data.tables <- subset(data.tables, PLAYTIME>0)
data.tables <- data.tables[order(data.tables$PLAYTIME, decreasing=F),]
dbDisconnect(dbconnector)

write.table(data.tables, "./test.csv", sep = ",", quote=F, col.names=F)

library(ggplot2)
p <- qplot(PLAYTIME,data=data.tables,geom="histogram",binwidth=1,xlab="PlayBackTime[s]",ylab="Count")
p <- p + ggtitle("#{strTime}")
ggsave("/home/kitada/waral_bot/data/n5P5mAZLtO4_#{strTime}.pdf",plot = p)
ggsave("/home/kitada/public_html/graph/n5P5mAZLtO4.png",plot = p)

RCOMMAND

#集合的笑い回数の集計

#配列と変数の宣言
count = 0
num = []
timecode = []
playbacktime = 256

#１秒毎の笑い回数を取得する
for i in 0..playbacktime
CSV.foreach("./test.csv"){ |row|

	#playtimeを格納し，数値に変換する
	playtime = row[4].to_i

	#i秒以上かつi-1秒未満
	if(playtime <= i && playtime > i-1) then

		#文字列を数値に変換する
		num.push(row[4].to_f)
	end
}

#笑い回数を変数に格納
count = num.size
#CSV保存用の配列に格納
timecode << ["#{i}","#{count}"]
#配列の初期化
num.clear

end

#1秒間あたりの笑い数のCSVファイルの新規・上書き保存
csv_line_write = CSV.open("./csv/output_#{strTime}.csv", "w")
timecode.each do |row|
	csv_line_write << row
end

#Rplots.pdfとtest.csvを削除する
File.delete("./Rplots.pdf")
File.delete("./test.csv")

#Twitterに投稿
begin
	client = Twitter::REST::Client.new do |config|
		config.consumer_key       	= "38SzpCRhlej6khJnriP5IQ"
		config.consumer_secret    	= "LpgJqTbTQGikGc2zRRkgLeCNhvgm3EbkHLMHe2JJjo"
		config.access_token 	  	= "2311188614-6tOExygAm8twjTrd1ONj0YcLkKmyGDuQc69aPx2"
		config.access_token_secret	= "T7mAl7BsIrkV3wOE38FnoVcb6KiOEnbrgJ4kxYDZZ7FIk"
	end

	#Post an update with an image
	client.update_with_media("スマホで動画コンテンツの面白さの度合いを計測できるWebアプリ「ワラエル」http://j.mp/waral126（iOS/Android専用）ただいまの実験結果はこちら！",
		File.new("/home/kitada/public_html/graph/n5P5mAZLtO4.png"))

rescue => e
  STDERR.puts "[EXCEPTION] " + e.to_s
  exit 1
end