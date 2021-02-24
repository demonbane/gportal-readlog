readlog : src/header lib/readlog.awk src/footer
	cat src/header lib/readlog.awk src/footer > readlog
	chmod 755 readlog

readlog-valheim : src/valheim-header lib/valheim.awk src/footer
	cat src/valheim-header lib/valheim.awk src/footer > readlog-valheim
	chmod 755 readlog-valheim

clean :
	rm -f readlog readlog-valheim
