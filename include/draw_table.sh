echoSpace() {
	local tmp=$1
	while (( $tmp > 0 )); do
		tmp=$(($tmp-1))
		echo -n " "
	done
}

echoHLine() {
	local tmp=$1
	while (( $tmp > 0 ))
	do
		tmp=$(($tmp-1))
		echo -n "═"
	done
}

echoVLine() {
	echo -n "║"
}

echoLT() {
	echo -n "╔"
}

echoRT() {
	echo -n "╗"
}

echoMT() {
	echo -n "╦"
}

echoLM() {
	echo -n "╠"
}

echoMM() {
	echo -n "╬"
}

echoRM() {
	echo -n "╣"
}

echoLB() {
	echo -n "╚"
}

echoMB() {
	echo -n "╩"
}

echoRB() {
	echo -n "╝"
}

tableHead() {
	# ╔════╦═══════╗
	echoLT
	echoHLine $(($1+2))
	shift
	for tmp in $@;
	do
		echoMT
		echoHLine $(($tmp+2))
	done
	echoRT
}

tableMid() {
	# ╠════╬═══════╣
	echoLM
	echoHLine $(($1+2))
	shift
	for tmp in $@;
	do
		echoMM
		echoHLine $(($tmp+2))
	done
	echoRM
}

tableBottom() {
	# ╚═══╩════════╝
	echoLB
	echoHLine $(($1+2))
	shift
	for tmp in $@;
	do
		echoMB
		echoHLine $(($tmp+2))
	done
	echoRB
}


