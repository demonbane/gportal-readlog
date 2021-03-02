BEGIN{
	FS=": "
}

/^[0-9/ :]+Got character ZDOID from/ {
	timestamp=tounix($1)
	if (timestamp < starttime)
		next
	split($2, somewords, " ")
	username=join(somewords, 5)
	if ($3 == "0:0") {
		deaths[username]++
		if (debug)
			print username,"died at",strftime("%R %D", tounix($1),0)
		next
	}
	split($3, uidparts, ":")
	split(users[username], suidparts, ":")
	id=$3
	users[username]=id
	userids[id]=username
	if (suidparts[1] == uidparts[1])
		next
	logintime[username]=timestamp
	logouttime[username]=""
	#print username,"logged in at",strftime("%+", timestamp, 0),"with ID",id
}

/^[0-9/ :]+Destroying abandoned non persistent zdo/ {
	split($2, somewords, " ")
	id=somewords[6]
	username=userids[id]
	timestamp=tounix($1)
	logouttime[username]=timestamp
	duration=logouttime[username] - logintime[username]
	totalduration[username]+=duration
	totaldeaths[username]+=deaths[username]
	if (username) {
		printlogout()
		#print username,"logged in from",strftime("%R %D", logintime[username], 0),"to",strftime("%R %D", logouttime[username]),"for a total of",totime(duration)
	}
}

END {
	for (username in logintime)
		if (username && ! logouttime[username]) {
			duration=systime() - logintime[username]
			totalduration[username]+=duration
			printlogout()
		}
	if (length(totalduration) == 0)
		exit 1
	print "\nTOTALS:"
	for (username in totalduration)
		if (username)
			print username":",totime(totalduration[username]),"("totaldeaths[username],"deaths)"
}

function printlogout() {
	message=username" logged in from "strftime("%R %D", logintime[username], 0)
	if (logouttime[username])
		message=message" to "strftime("%R %D", logouttime[username])
	if (deaths[username] == 1)
		message=message" and died once"
	else if (deaths[username] > 1)
		message=message" and died "deaths[username]" times"
	message=message" for a total of "totime(duration)
	deaths[username]=0

	print message
}

function tounix(s,   timestr, timespec, patparts) {
	patsplit(s, patparts, "[[:digit:]]+")
	timestr=join(patparts, 4, 6)
	daystr=patparts[3]" "patparts[1]" "patparts[2]
	timestr=daystr" "timestr
	timespec=mktime(timestr, 1)
	#The logs appear to be in CET instead of UTC, so adjust
	return timespec - 3600
}

function join(array, start, end, sep,    result, i) {
	if (length(array) == 0)
		return
	if (sep == "")
		sep = " "
	else if (sep == SUBSEP) # magic value
		sep = ""

	if (!start)
		start=1

	if (!end)
		end=length(array)

	result = array[start]
	for (i = start + 1; i <= end; i++)
		result = result sep array[i]
	return result
}

function totime(s,   hours, minutes, seconds) {
	hours=int(s/60/60)
	s -= (hours*60*60)
	minutes=int(s/60)
	s -= (minutes*60)
	seconds = s
	return sprintf("%ih %im %is", hours, minutes, seconds)
}
