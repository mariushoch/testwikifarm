#!/bin/bats

teardown() {
	# Print last output from bats' run
	# bats will not output anything, if the test succeeded.
	if [ -n "$output" ]; then
		echo "Last \$output:"
		echo "$output"
	fi
}

@test "Test that the wikis are accessible" {
	curl -v -L --fail 'http://dewiki.mediawiki.mwdd.localhost:8080/wiki/Special:BlankPage'
	curl -v -L --fail 'http://enwiki.mediawiki.mwdd.localhost:8080/wiki/Special:BlankPage'
	curl -v -L --fail 'http://metawiki.mediawiki.mwdd.localhost:8080/wiki/Special:BlankPage'
	curl -v -L --fail 'http://wikidatawiki.mediawiki.mwdd.localhost:8080/wiki/Special:BlankPage'
}
@test "mw docker mediawiki doctor" {
	mw docker mediawiki doctor
}
@test "Edit an enwiki page" {
	mw wiki page put --wiki http://enwiki.mediawiki.mwdd.localhost:8080/w/api.php --user admin --password mwddpassword --title Berlin <<< "BeRLiN"

	run curl -v -L --fail 'http://enwiki.mediawiki.mwdd.localhost:8080/wiki/Berlin'
	[[ "$output" =~ BeRLiN ]]
	[ "$status" -eq 0 ]
}
@test "mw docker mediawiki foreachwiki runJobs" {
	mw docker mediawiki foreachwiki runJobs
}
@test "CentralAuth" {
	# Note: This requires a successful login to "Admin"
	run sh -c "curl -s --fail 'http://dewiki.mediawiki.mwdd.localhost:8080/w/api.php?action=query&meta=globaluserinfo&guiuser=Admin&format=json&guiprop=merged' | jq -r '.query.globaluserinfo.merged[].wiki' | sort | paste -s -d -"
	[[ "$output" == "dewiki-enwiki-metawiki-wikidatawiki" ]]
	[ "$status" -eq 0 ]
}
