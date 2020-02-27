#!/bin/bash
. ./include/draw_table.sh
regions_file="config/regions.txt"
email_file="config/email_info.txt"
items_id_file="config/items_id.txt"
items_name_dir="config/items_name"
regions_en_file="config/regions_en.txt"
regions_url_file="config/regions_url.txt"

RED='\e[1;31m'    # 红色
GREEN='\e[1;32m'  # 绿色
YELLOW='\e[1;33m' # 黄色
BLUE='\e[1;34m'   # 蓝色
PINK='\e[1;35m'   # 粉色
RES='\e[0m'       # 清除颜色

getEmailInfo() {
	email=`cat $email_file`
}

getRegionsInfo() {
	regions=(`cat $regions_file`)
	regions_en=(`cat $regions_en_file`)
	regions_url=(`cat $regions_url_file`)
	region_cnt=${#regions_en}
}

getItemsInfo() {
	items_id=(`cat $items_id_file`)
	item_cnt=${#items_id[@]}
	items_name=()
	if (( $item_cnt > 0));then
		n=0
		for en in ${regions_en[@]};
		do
			while read LINE;
			do
				items_name[$n]=$LINE
				let n++
			done < $items_name_dir/${en}.txt
		done
	fi
	items_name_cnt=n
}

getInfo() {
	getEmailInfo
	getRegionsInfo
	getItemsInfo
}

runMonitor() {
	# check monitor running status
	echo -e "${YELLOW}Run Monitor Action${RES}"
	run_info=`ps -ef | grep get_price.sh | grep -v 'grep'`
	if [ -n "$run_info" ];then
		echo -e "${YELLOW}The Monitor is Running!${RES}"
	else
# TODO check environment like 'heirloom-mailx'
		# update INFO
		getInfo
		# email check
        if [ ! -n $email ];then
            # email is empty
			skip_mail_test=1
            echo -e "${RED}Please Set Your E-Mail First!${RES}"
            return 0
        fi
		if [ ! $skip_mail_test ];then
        	# send test mail
	        echo -e "${BLUE}send mail to $email, Please Check your postbox is there have the test mail${RES}"
	        echo -e "Mail Test" | mail -s "Test" $email
	        read -p "Have the test mail? [y/n]: " reply
	        if [ $reply = "y" ];then
				# run monitor
				echo -e "${GREEN}Start Run Monitor${RES}"
				setsid ./get_price.sh &
			else
	            echo -e "${RED}Please check your e-mail! ${RES}"
	            return 0
	        fi
		else
			echo -e "${GREEN}Start Run Monitor${RES}"
			setsid ./get_price.sh &
		fi
	fi
    return 1
}

stopMonitor() {
	echo -e "${YELLOW}Stop Monitor Action${RES}"
    # check monitor running status
	run_info=`ps -ef | grep get_price.sh | grep -v 'grep'`
	if [ -n "$run_info" ];then
        pid=`echo $run_info | awk '{print $2}'`
        echo "run info is: "$run_info
        echo "pid is: "$pid
        read -p "Are you sure to stop the monitor? [y/n]: " reply
        if [ $reply = "y" ];then
            kill $pid
            echo -e "${GREEN}Monitor Stoped!${RES}"
        else
            echo -e "${YELLOW}Aband${RES}"
            return 0
        fi
	else
        echo -e "${YELLOW}There is no monitor running!${RES}"
    fi
    return 1  
}

restartMonitor() {
	skip_mail_test=true
	echo -e "${YELLOW}Restart Monitor Action${RES}"
	stopMonitor
	if (( $? == 0 ));then
		echo -e "${RED}Stop Monitor Failed!${RES}"
		return 0
	fi
	runMonitor
	if (( $? == 0 ));then
		echo -e "${RED}Start Monitor Failed${RES}"
		return 0
	fi
	echo -e "${GREEN}Restart Monitor Success!${RES}"
	return 1
}

getLength() {
	length=${#1}
	letters=(`echo $1 | sed "s/[^\n]/&\n/g"`)
	for letter in ${letters[@]};
	do
		if (( `expr length $letter` == 3 ));then
			let length++
		fi
	done
}

tableMsg() {
# tableMsg $i $name
	# ║ i ║ XXXXXXXX ║
	id=$1
	name=$2
	cnt1=${#id}
	getLength "$name"
	cnt2=$length
	echoVLine
	echoSpace $(($cnt_len-$cnt1+1))
	echo -n $id" "
	echoVLine
	echo -n " "$name
	echoSpace $(($max-$length+1))
	echoVLine
}

echoItemBlock() {
	tableMsg $1 "${items_name[$1]}"; echo
	for((tmp2=1;tmp2<$region_cnt;tmp2++));
	do
		tableMid $cnt_len $max; echo
		tableMsg $1 "${items_name[$(($1+$item_cnt))]}"; echo
	done
}


showItemsName() {
	getItemsInfo
	if (( $item_cnt == 0 ));then
		echo -e "${YELLOW}No Item under Monitoring NOW${RES}"
		return
	fi
	max=0
	for((tmp=0;tmp<$items_name_cnt;tmp++));
	do
		#TODO Find a better way to get the Chinese word length
		getLength "${items_name[$tmp]}"
		if (( $length > $max ));then
			max=$length
		fi
	done
	cnt_len=${#item_cnt}
	local i=0
	while (( $i < $item_cnt ));
	do
		if (( $i == 0 ));then
			tableHead $cnt_len $max
			echo
		else
			tableMid $cnt_len $max
			echo
		fi
		echoItemBlock $i
		let i++
	done
	tableBottom $cnt_len $max
	echo
}


if [ ! -d $items_name_dir ];then
	mkdir "$items_name_dir"
fi

getInfo

while true
do
    echo "╔=════════════════════════════════════╗"
    echo "║                 MENU                ║"
    echo "╠═══╦═════════════════════════════════╣"
    echo "║ 0 ║ Run App Store Price Monitor.    ║"
    echo "╠═══╬═════════════════════════════════╣"
	echo "║ 1 ║ Stop App Store Price Monitor.   ║"
    echo "╠═══╬═════════════════════════════════╣"
	echo "║ 2 ║ Restart App Store Price Monitor.║"
    echo "╠═══╬═════════════════════════════════╣"
	echo "║ 3 ║ Change/Set Recive E-Mail.       ║"
    echo "╠═══╬═════════════════════════════════╣"
	echo "║ 4 ║ Add Monitor Application.        ║"
    echo "╠═══╬═════════════════════════════════╣"
	echo "║ 5 ║ Remove Monitor Application.     ║"
    echo "╠═══╬═════════════════════════════════╣"
	echo "║ 6 ║ Exit.                           ║"
    echo "╚═══╩═════════════════════════════════╝"
    read -p "Enter your choise [0-6]:" option
    case $option in
	0)
		# run monitor
        runMonitor
		;;
	1)
        # stop monitor
        stopMonitor
		;;
	2)
		# restart monitor
		restartMonitor
		;;
	3)
        # change/set recive e-mail
		echo -e "${BLUE}Setted e-mail: `cat $email_file`${RES}"
        read -p "Please input NEW e-mail: " email
		echo -e "${YELLOW}Are you sure set e-mail `cat $email_file` -> $email${RES}"
		echo -en "${YELLOW}[y/n]? : ${RES}"
		read reply
		if [ $reply = "y" ];then
	        echo $email > $email_file
			echo -e "${GREEN}E-Mail set success!${RES}"
        	restartMonitor
		else
			echo -e "${YELLOW}Aband set email${RES}"
		fi
		;;
	4)
        # add monitor application
		added=false
		while true; do
			echo -e "${BLUE}Items under Monitoring: "
			showItemsName
			echo -en "${YELLOW}Confirm whether to add new item? [y/n]: ${RES}"
			read reply
			if [ $reply = "y" ];then
    		    read -p "Please input App Store link of the app: " url
    		    # chekc url
				# get_id
				item_id=${url##*/id}
				echo -e "${GREEN}item_id = ${item_id}${RES}"
				
				item_id=${item_id%%\?*}
				echo -e "${GREEN}item_id = ${item_id}${RES}"
				
				item_name=
				for((tmp=0;tmp<$region_cnt;tmp++));
				do
					result=`curl -s ${regions_url[$tmp]}${item_id}`
					resultCount=`echo $result | jq .'resultCount'`
					
					echo "region = ${regions[$tmp]}"
					if (( $resultCount == 0));then
						item_name[$tmp]="none"
						echo -e "${RED}no such app in ${regions_en[$tmp]} App Store!${RES}"
					else
						item_name[$tmp]=`echo $result | jq .'results'[0].'trackName' | sed 's/\"//g'`
						softtype=`echo $result | jq .'results'[0].'kind' | sed 's/\"//g'`
						if [ $softtype = "mac-software" ];then
							softtype="mac"
						else
							softtype="ios"
						fi
						item_name[$tmp]="${item_name[$tmp]} [${softtype} | ${regions_en[$tmp]}]"
    				    echo "title  = ${item_name[$tmp]}"
    			    	echo "price  = "`echo $result | jq .'results'[0].'formattedPrice' | sed 's/\"//g'`
					fi
				done

    		    read -p "Is this info right? [y/n]: " reply
				if [ $reply = "n" ];then
    		        echo -e "${YELLOW}Aband add monitor${RES}"
    		    else
					for((tmp=0;tmp<$region_cnt;tmp++));
					do
						echo ${item_name[$tmp]} >> $items_name_dir/${regions_en[$tmp]}.txt
						echo -e "${GREEN}${item_name[$tmp]} add to $items_name_dir/${regions_en[$tmp]}.txt${RES}"
					done
    		        echo $item_id >> $items_id_file
					echo -e "${GREEN}$item_id add to $items_id_file${RES}"
    		        echo -e "${GREEN}Application info added${RES}"
					added=true
				fi

			else
				break
			fi
		done
		if [ $added = true ];then
			restartMonitor
		fi
		;;
	5)
        # remove monitor application
		deleted=false
		while true; do
			echo -e "${BLUE}Items under Monitoring: "
			showItemsName
			echo -en "${YELLOW}Confirm whether to remove item? [y/n]: ${RES}"
			read reply
			if [ $reply = "y" ];then
				showItemsName
				num=$item_cnt
				read -p "Please input the number to DEL:[0-$(($num-1))] " reply
				if (( $reply >= 0 )) && (( $reply < $num ));then
					echo -e "${YELLOW}Are you sure to del below app monitor?"
					tableHead $cnt_len $max; echo
					echoItemBlock $reply
					tableBottom $cnt_len $max; echo
					echo -en "[y/n]? : ${RES}"
					read ans
					if [ $ans = "y" ];then
						for en in ${regions_en[@]};
						do
							sed -i $(($reply+1))'d' $items_name_dir/$en.txt
						done
						sed -i $(($reply+1))'d' $items_id_file
						echo -e "${GREEN}Application info deleted${RES}"
						deleted=true
					else
						echo -e "${YELLOW}Aband${RES}"
					fi
				else
					echo -e "${RED}Error: Invalid number!${RES}"
				fi
			else
				break
			fi
		done
		if [ $deleted = true ];then
			restartMonitor
		fi
		;;
	6)
		# exit
		break
		;;
	*)
		echo -e "\e[31m Error: Invalid option! ${RES}"
		;;
	esac
	read -p "Press [Enter] key to continue..." readEnterKey
done
