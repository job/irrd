#!/bin/bash
set -o errexit

function run_tests {
    mkdir -p /tmp/irr/pgp_dir /tmp/irr/log
    sudo irrd -f irrd.conf &
    sleep 2
    tests_round_1
    tests_with_pwhash_hiding
    killirrd
}

function reload_irrd {
    # relaod the database with maintainer which has crypt, md5 and pgp auth
    (   echo "admin_citesting" 
        sleep 2 
        echo -e "reload sampledb\n\r" 
        sleep 2 ) | telnet localhost 5673 
    sleep 2
    whois -h localhost MAINT-TEST
}

function run {
    haystack=$(${1} | tee /dev/tty)
    needle=${2}
    wrong=${3}
    if [[ ${haystack} = *${wrong}* ]]; then
        echo "Bad indicator \"${wrong}\" found, aborting"
        exit 2
    fi
    if [[ ${haystack} = *${needle}* ]]; then
        echo "OK indicator \"${needle}\" found"
    else
        echo "Could not find success indicator \"${needle}\" in this test, aborting"
        exit 2
    fi
}

function test_001 {
    echo "INFO: testing object creation authenticated with UNIX crypt password"
    irr_rpsl_submit -v -f irrd.conf -s sampledb -x < test_001_upload_certif_with_unixcrypt.txt
    sleep 2
    whois -h localhost TESTUSER-sampledb
}

function test_002 {
    echo "INFO: testing object modification authenticated with MD5 password"
    irr_rpsl_submit -v -f irrd.conf -s sampledb -x < test_002_modify_person_with_md5.txt
    sleep 2
    whois -h localhost TESTUSER-sampledb
}

function test_003 {
    echo "INFO: testing object modification authenticated with GPG signature"
    irr_rpsl_submit -v -f irrd.conf -s sampledb -x < test_003_modify_person_with_gpg.txt
    sleep 2
    whois -h localhost TESTUSER-sampledb
}

function test_004 {
    echo "INFO: testing heasely's i6 patch"
    irr_rpsl_submit -v -f irrd.conf -s sampledb -x < test_004_test_heasely_i6.txt
    sleep 2
    whois -h localhost AS1:AS-ALL
    echo
    echo INFO: this should list a mix of ASN and AS_SET
    whois -h localhost '!i6AS1:AS-ALL'
    echo
    echo INFO: this should list be a list of only ASN
    whois -h localhost '!i6AS1:AS-ALL,1'
}

function tests_round_1 {
    # empty the database and insert first maintainer
    cat test_000_insert_maint.txt | sudo tee /var/spool/irr_database/sampledb.db
    run reload_irrd "Success" "Error"

    echo; echo
    run test_001 "ADD OK: " "ADD FAILED"
    echo; echo
    run test_002 "REPLACE OK: " "FAILED"
    echo; echo
    run test_003 "REPLACE OK: " "FAILED"
    echo; echo
    run test_004 "OK" "FAIL"
    echo; echo
    # the following essentially is test_005
    # run show_irrd_config "sampledb" "FAIL"
    # see https://travis-ci.org/job/irrd/builds/34656137 for a round 1 failure
}

function tests_with_pwhash_hiding {
    echo "INFO: applying ACL for password hash hiding to the running daemon"
    (   echo "admin_citesting"
    sleep 2
    echo -e "config\n\r"
    sleep 2
    echo -e "irr_database sampledb cryptpw-access 99\n\r"
    sleep 2
    echo -e "exit\n\r"; sleep 2
    echo -e "exit\n\r"; sleep 2 ) | telnet localhost 5673 || echo
    tests_round_1
}

function show_irrd_config {
    (   echo "admin_citesting"
    sleep 2
    echo -e "show config\n\r"
    sleep 2
    echo -e "exit\n\r";
    sleep 2 ) | telnet localhost 5673 || echo
}


function rebootirrd {
    # reboot
    (   echo "admin_citesting"
        sleep 2
        echo "reboot"
        sleep 2 ) | telnet localhost 5673 || echo
    sleep 5
}

function killirrd {
    # kill irrd
    (   echo "admin_citesting"
        sleep 2
        echo "kill"
        sleep 2 ) | telnet localhost 5673 || echo
}

run_tests
