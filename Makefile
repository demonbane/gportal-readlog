readlog : src/header lib/readlog.awk src/footer
	cat src/header lib/readlog.awk src/footer > readlog
	chmod 755 readlog

clean :
	rm -f readlog
