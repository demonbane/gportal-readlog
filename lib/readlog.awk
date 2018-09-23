BEGIN {
	FS="\\?"
	username[1]="someone"
	username[2]="someone"
	userip[1]="empty"
	userip[2]="empty"
}

/^\[[[:digit:].\-:]+\]\[ [[:digit:]]{2}\]/ { sub(/\[ [[:digit:]]{2}\]/, "[999]") }

/players=[0-9]/ {
	split($2, preval, /=/)
	split(preval[2], vals, /\&/)
	players=vals[1]
	if (players == oldplayers)
		next
	else {
		oldplayers=players
		color=32+players
		printf "\033[1;%sm%s\033[0m %s players", color, localtime($0), players
		if (players==1)
			printf ", " username[1]
		else if (players==2)
			printf ", " username[1] ", " username[2]

		print ""
	}
}

function localtime(s) {
	patsplit(s, patparts, "[[:digit:]]+")
	timestr=join(patparts, 1, 6)
	timespec=mktime(timestr, 1)
	return strftime(PROCINFO["strftime"], timespec)
}

function join(array, start, end, sep,    result, i)
{
    if (sep == "")
       sep = " "
    else if (sep == SUBSEP) # magic value
       sep = ""
    result = array[start]
    for (i = start + 1; i <= end; i++)
        result = result sep array[i]
    return result
}

/Join succeeded/ {
	split($0, myfields, "[ \n\r\t]+")
	if (userip[1]=="empty" || username[1]=="someone")
		curid=1
	else if (userip[2]=="empty" || username[2]=="someone")
		curid=2

	if (userip[curid]=="empty")
		userip[1]="unknown"

	if (myfields[4]=="succeeded:")
		print $0
	username[curid]=myfields[4]
}

/Client login from/ {
	split($0, myfields, "[ \n\r\t,]+")
	if (userip[1]=="empty")
		userip[1]=myfields[5]
	else
		userip[2]=myfields[5]
}

/Closing connection.*RemoteAddr:/ {
	split($0, myfields, ":")
	gsub(/ /, "", myfields[9])
	if (userip[1]==myfields[9])
		userid=1
	else if (userip[2]==myfields[9])
		userid=2

	if (userid==1 && username[2]!="empty") {
		username[1]=username[2]
		userip[1]=userip[2]
		userid=2
	}

	if (userid) {
		username[userid]="someone"
		userip[userid]="empty"
	} else
		print "No user found for IP='" myfields[9] "'"
}

