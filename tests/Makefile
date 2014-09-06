# FIXME: a more elegant 'test for this string's absence or presence method should be created

test:
	mkdir -p /tmp/irr/pgp_dir /tmp/irr/log
	sudo irrd -f irrd.conf &
	@sleep 1

	# empty the database and insert first maintainer
	cat test_000_insert_maint.txt | sudo tee /var/spool/irr_database/sampledb.db
	
	# relaod the database with maintainer which has crypt, md5 and pgp auth
	(echo admin_citesting; sleep 2; echo "reload sampledb\n\r"; sleep 2; exit) | telnet localhost 5673 || echo
	@sleep 1
	whois -h localhost MAINT-TEST

	@echo
	@echo

	@echo "INFO: testing object creation authenticated with UNIX crypt password"
	irr_rpsl_submit -v -f irrd.conf -s sampledb -x < test_001_upload_certif_with_unixcrypt.txt | tee /dev/tty | grep "OK:"
	@sleep 1
	whois -h localhost TESTUSER-sampledb

	@echo
	@echo

	@echo "INFO: testing object modification authenticated with MD5 password"
	irr_rpsl_submit -v -f irrd.conf -s sampledb -x < test_002_modify_person_with_md5.txt | tee /dev/tty | grep "OK:"
	@sleep 1
	whois -h localhost TESTUSER-sampledb

	@echo
	@echo

	@echo "INFO: testing heasely's i6 patch"
	irr_rpsl_submit -v -f irrd.conf -s sampledb -x < test_004_test_heasely_i6.txt | tee /dev/tty | grep "OK:"
	@sleep 1
	whois -h localhost AS1:AS-ALL
	
	echo '!i6AS1:AS-ALL' | telnet localhost 43

	# kill irrd
	(echo admin_citesting; sleep 2; echo "kill\n\r"; sleep 1; echo "yes\n\r") | telnet localhost 5673 || echo
