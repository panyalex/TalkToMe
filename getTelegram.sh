direkt_oder_ab(){
#Prüft mit ARP-paketen, ob daheim, wird 4 mal gefragt, ob handy im netz is
for ((i = 1; i <= 4; i++)); do
	ishome='ishome'
	homeornot=$(sudo bash isphonehome.sh)
	if [ $homeornot == $ishome ]
	then	
#		echo "handy is da"
		echo 0 > gpiobutton.txt
		break
	else
		if  ((i == 4))
		then
			echo 1 > gpiobutton.txt
			python3 hardware.py &
#			echo "handy ned zuhause"
		fi
	fi
	sleep 3
done
}

ab_return(){
#wird ausgeführt, wenn nachrichten auf dem AB sind und der Knopf gedrückt wird
	if [[ $anrufbeantworter == "2" ]]
		then
#		echo "Ab wurde aufgerufen"
		pulseaudio --start
		pid=$(ps aux | grep hardware.py | grep -v grep | awk '{print $2}')
		kill $pid
		xargs -a abnachrichten.txt cvlc --play-and-exit
		echo "" > abnachrichten.txt
		echo 0 > gpiobutton.txt
	fi
}
init_ab(){
	anrufbeantworter=$(cat gpiobutton.txt)
	if [[ $anrufbeantworter == "1" ]]
	then
		python3 hardware.py &
	fi
}
#Einholen der Daten: Zuletzt ausgeführte MessageID und die Vollständige getUpdate JSON
botkey=$(cat botkey.txt)
init_ab
while true;
do
oldmessageid=$(cat MessageID.txt)
anrufbeantworter=$(cat gpiobutton.txt)
fullmessage=$(curl -s "https://api.telegram.org/bot"$botkey"/getUpdates");
#Ab abspielen, zurücksetzen
ab_return
newmessage=$"true"
isnewmessage=$(echo "$fullmessage" | jq '.ok')
#Wenn überhaupt n telegram json vorliegt
if [ $isnewmessage != $newmessage ];
	then
	sleep 30
	else
	#updateid=$(echo "$fullmessage" | jq '.result' | jq  'length' )

	messageid=$(echo "$fullmessage" | jq '.result[].message.message_id' | tail -n 1);
	#wenn die letzte nachricht ne neue ID hat
	if [ $oldmessageid == $messageid ]; 
		then
		text=$(echo "$fullmessage" | jq '.result[].message.text' | tail -n 1);
		text="${text:1: -1}";

		username=$(echo "$fullmessage" | jq '.result[].message.from.first_name' | tail -n 1);
		username="${username:1: -1}";
                userid=$(echo "$fullmessage" | jq '.result[].message.from.id' | tail -n 1);
                messageid=$((messageid +2));

                echo $messageid > MessageID.txt

		filename=$(echo $messageid$username".wav")
#Nachricht von X
		nachrichtvon=$(echo $username".wav")
		#wenn der absender noch nie ne nachricht gesendet hat
		if test -e messages/$nachrichtvon;
			then
			echo 1 > /dev/null
			else
			echo "Nachricht von" $username | piper/piper --length_scale 1.5 --model de_DE-thorsten-medium.onnx --output_file messages/$nachrichtvon
		fi
#Testen ob daheim, oder ned
		direkt_oder_ab
#Nachricht wird zu speech ungewandelt
		echo $text | piper/piper --length_scale 1.5 --model de_DE-thorsten-medium.onnx --output_file messages/$filename
#Nachricht wird abgespielt oder im AB gespeichert
		anrufbeantworter=$(cat gpiobutton.txt)
		if [[ $anrufbeantworter == "0" ]]
                then
			curl -s "https://api.telegram.org/bot"$botkey"/sendMessage?chat_id="$userid"&text=Nachricht wurde abgespielt"
			pulseaudio --start
			sleep 1
			cvlc --play-and-exit messages/$nachrichtvon messages/$filename
		elif [[ $anrufbeantworter == "1" ]]
		then
			curl -s "https://api.telegram.org/bot"$botkey"/sendMessage?chat_id="$userid"&text=Nachricht wurde auf dem Anrufbeantworter gespeichert"
			echo messages/$nachrichtvon messages/$filename >> abnachrichten.txt
		fi

		#echo Kam heute ne neue Nachricht : $newmessage
		#echo UpdateID : $updateid
		#echo MessageID : $messageid
		#echo Old MessageID : $oldmessageid
		#echo Nachricht : $text
		#echo UserID : $userid
		else
		sleep 10
	fi
fi

done
