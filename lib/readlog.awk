BEGIN {
	FS=": "
}

{ lastline=$0 }

ENDFILE {
	if (lastline !~ /Log file closed/) {
		for (userid in users) {
			if (users[userid]["status"] == "connected") {
				daytotal[users[userid]["name"]] += (tounix(lastline) - users[userid]["starttime"])
				users[userid]["status"] = "ended"
			}
		}
	}
	delete users
	if (isarray(daytotal) && length(daytotal) > 0) {
		printf "\n"
		for (username in daytotal) {
			grandtotal[username] += daytotal[username]
			printf "Today for %s: %s\n", username, totime(daytotal[username])
		}
		printf "\n\n"
		delete daytotal
	}
}

END {
	if (isarray(grandtotal) && length(grandtotal) > 0)
		for (username in grandtotal)
			printf "Total for %s: %s\n", username, totime(grandtotal[username])
}

function getdetails(uids, uips,   preval, portval) {
	delete thisuser
	split(uids, preval, /[,_]/)
	thisuser["id"] = preval[2]

	split(uips, preval, /:/)
	thisuser["ip"] = preval[1]

	split(preval[2], portval, /, /)
	thisuser["port"] = portval[1]
}

function tounix(s,   timestr, timespec, patparts) {
	patsplit(s, patparts, "[[:digit:]]+")
	timestr=join(patparts, 1, 6)
	timespec=mktime(timestr, 1)
	return timespec
}

function totime(s,   hours, minutes, seconds) {
	hours=int(s/60/60)
	s -= (hours*60*60)
	minutes=int(s/60)
	s -= (minutes*60)
	seconds = s
	return sprintf("%ih %im %is", hours, minutes, seconds)
}

function localtime(s,   timespec) {
	timespec = tounix(s)
	return strftime(PROCINFO["strftime"], timespec)
}

function join(array, start, end, sep,    result, i) {
    if (sep == "")
       sep = " "
    else if (sep == SUBSEP) # magic value
       sep = ""
    result = array[start]
    for (i = start + 1; i <= end; i++)
        result = result sep array[i]
    return result
}

function connectedusers(   connectedcount, connected) {
	connectedcount=0
	connected=""
	for (userid in users) {
		if (users[userid]["status"] == "connected") {
			connectedcount++
			if (connected)
				connected = connected", "users[userid]["name"]
			else
				connected = ", "users[userid]["name"]
		}
	}
	color=32+connectedcount
	printf "\033[1;%im%s\033[0m %s players%s\n", color, localtime($1), connectedcount, connected
}

/LogNet: AddClientConnection:/ {
	getdetails($6, $5)
	userid=thisuser["id"]

	if (userid in users) {
		print $0
		print "userid already exists, aborting"
		exit 1
	}

	users[userid]["ip"] = thisuser["ip"]
	users[userid]["port"] = thisuser["port"]
	users[userid]["status"] = "pending"
}

/Join succeeded/ {
	split($3, myfields, "[ \n\r\t]+")
	username=myfields[1]

	for (userid in users) {
		if (users[userid]["status"] == "pending") {
			if (pendingid) {
				print "Multiple pending logins, aborting"
				exit 1
			}
			pendingid = userid
		}else if (users[userid]["status"] == "connected") {
			if (connected && users[userid]["name"]) {
				connected = connected" ,"users[userid]["name"]
				connectedcount++
			}else if (users[userid]["name"]) {
				connected = users[userid]["name"]
				connectedcount++
			}
		}
	}

	if (!pendingid) {
		print $0
		print "Unable to find pending login, aborting"
		exit 1
	}

	if (connected)
		connected = connected", "username
	else
		connectedcount=1

	users[pendingid]["name"] = username
	users[pendingid]["status"] = "connected"
	users[pendingid]["starttime"] = tounix($0)

	connectedusers()
	pendingid=""
}

/LogNet: UChannel::Close/ {
	getdetails($8, $7)
	userid = thisuser["id"]
	#users[thisuser["id"]]["status"] = "closed"
	endtime=tounix($0)
	if (users[userid]["status"] == "connected"){
		elapsed = (endtime - users[userid]["starttime"])
		daytotal[users[userid]["name"]] += elapsed
	}
	delete users[userid]
	connectedusers()
	userid=""
}
