#!/bin/bash
head_file="include/head.html"
footer_file="include/footer.html"
tmp_file="tmp/tmp.html"
tmp_mail_file="tmp/mail_content.html"

items_id=(`cat config/items_id.txt`)
regions=(`cat config/regions.txt`)
regions_en=(`cat config/regions_en.txt`)
regions_url=(`cat config/regions_url.txt`)
email=`cat config/email_info.txt`
checkDirFun() {
	if [ ! -d "$1" ];then
		mkdir "$1"
		return 1
	fi
	return 0
}

item_cnt=${#items_id[@]}
region_cnt=${#regions[@]}

while true
do
	if [ -d "tmp" ];then
		rm -r tmp
	fi
	mkdir tmp
	# mail content
    for((i=0;i<$item_cnt;i++));
    do
		id=${items_id[$i]}
		for((j=0;j<$region_cnt;j++));
		do
			region=${regions[$j]}
    	    resultJson=`curl -s ${regions_url[$j]}${id}`
			resultCount=`echo $resultJson | jq .'resultCount'`
			if (( $resultCount == 0 ));then
				# no such application in the store
				continue
			fi
    	    price=`echo $resultJson | jq .'results'[0].'formattedPrice' | sed 's/\"//g'`
			price_num=${price:1}
			item_name=`echo $resultJson | jq .'results'[0].'trackName' | sed 's/\"//g'`
			img_link=`echo $resultJson | jq .'results'[0].'artworkUrl512'`
			category=`echo $resultJson | jq .'results'[0].'primaryGenreName' | sed 's/\"//g'`
			app_store_link=`echo $resultJson | jq .'results'[0].'trackViewUrl'`
			software_type=`echo $resultJson | jq .'results'[0].'kind' | sed 's/\"//g'`
			if [ $software_type = "mac-software" ];then
				software_type="macOS"
			else
				software_type="iOS"
			fi
			last_price=$price
			lowest_price=$price
			
			his_data="his_data"
			item_his_dir="$his_data/$id"
			his_file="$item_his_dir/history_${regions_en[$j]}.txt"
			price_file="$item_his_dir/price_${regions_en[$j]}.txt"

			record=`date +%Y/%m/%d'|'%T`" "$price

			checkDirFun "$his_data"
			checkDirFun "$item_his_dir"
			if [ -f "$his_file" ];then
				add_statu=0
			else
				add_statu=1
			fi

			echo $record >> "$his_file"

    	    if [ -f "$price_file" ];then
				his_price=(`cat $price_file`)
    	        last_price=${his_price[0]}
				lowest_price=${his_price[1]}
			fi

			lowest_price_num=${lowest_price:1}
			if (( `expr $lowest_price_num \> $price_num` ));then
				# update lowest_price
				lowest_price=$price
			fi

			last_price_num=${last_price:1}
    	    if (( `expr $last_price_num \> $price_num` ));then
    	        # price down
				color="green"
				symbol="&#9660;"
			elif (( `expr $last_price_num \< $price_num` ));then
				# price up
				color="red"
				symobl="&#9650;"
    	    else
				# price keep
				color="black"
				symbol=""
    	    fi

			if (( $add_statu == 1 ));then
				. ./include/item_html.sh
				echo "${tmp}" >> $tmp_file
			fi

			# update price_file
    	    echo $price > "$price_file"
			echo $lowest_price >> "$price_file"
		done
    done
    if [ -f "$tmp_file" ];then
        # content not null
		# combine mail
		cat $head_file > $tmp_mail_file
		cat $tmp_file >> $tmp_mail_file
		cat $footer_file >> $tmp_mail_file
        # send mail
		mail -s "$(echo -e "App Store 价格监控\nContent-Type: text/html")" $email < $tmp_mail_file
    fi
	sleep 1h
done
