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
@test "Edit an enwiki page and search for it using CirrusSearch" {
	mw wiki page put --wiki http://enwiki.mediawiki.mwdd.localhost:8080/w/api.php --user admin --password mwddpassword --title Berlin <<< "Info on BeRLiN"

	run curl -v -L --fail 'http://enwiki.mediawiki.mwdd.localhost:8080/wiki/Berlin?action=render'
	[[ "$output" =~ BeRLiN ]]
	[ "$status" -eq 0 ]

	mw docker mediawiki foreachwiki runJobs

	curl 'http://enwiki.mediawiki.mwdd.localhost:8080/w/api.php?action=query&list=search&srsearch=insource:BeRLiN&format=json' | jq -e '.query.searchinfo.totalhits == 1'
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
@test "Wikibase site links" {
	mw wiki page put --wiki http://enwiki.mediawiki.mwdd.localhost:8080/w/api.php --user admin --password mwddpassword --title Berlin <<< "EN"
	mw wiki page put --wiki http://dewiki.mediawiki.mwdd.localhost:8080/w/api.php --user admin --password mwddpassword --title Berlin <<< "DE"
	python "$BATS_TEST_DIRNAME"/link_en_de_berlin.py

	mw docker mediawiki foreachwiki runJobs
	mw docker mediawiki foreachwiki runJobs

	run curl -s --fail 'http://dewiki.mediawiki.mwdd.localhost:8080/w/api.php?action=query&prop=langlinks&titles=Berlin&format=json&formatversion=2'
	[[ "$(jq '.query.pages[].langlinks[].lang' <<< "$output")" == '"en"' ]]
	[ "$status" -eq 0 ]

	run curl -s --fail 'http://enwiki.mediawiki.mwdd.localhost:8080/w/api.php?action=query&prop=langlinks&titles=Berlin&format=json&formatversion=2'
	[[ "$(jq '.query.pages[].langlinks[].lang' <<< "$output")" == '"de"' ]]
	[ "$status" -eq 0 ]
}
@test "Wikibase Scribunto" {
	mw wiki page put --wiki http://enwiki.mediawiki.mwdd.localhost:8080/w/api.php --user admin --password mwddpassword --title Module:WikibaseScribuntoTest \
		<<< "return { wst = function() return 'BerlinID:' .. mw.wikibase.getEntityIdForTitle( 'Berlin' ) end }"
	mw wiki page put --wiki http://enwiki.mediawiki.mwdd.localhost:8080/w/api.php --user admin --password mwddpassword --title WikibaseScribuntoTest <<< "{{#invoke:WikibaseScribuntoTest|wst}}"
	run curl -v -L --fail 'http://enwiki.mediawiki.mwdd.localhost:8080/wiki/WikibaseScribuntoTest?action=render'
	[[ "$output" =~ BerlinID:Q[0-9]+ ]]
	[ "$status" -eq 0 ]
}
@test "Test mobile mode" {
	run curl -v -L --fail 'http://enwiki.mediawiki.mwdd.localhost:8080/wiki/Special:BlankPage?useformat=mobile'
	[ "$status" -eq 0 ]
	[[ "$output" =~ Special:MobileOptions ]]
	[[ "$output" =~ class=\"[^\"]*skin-minerva ]]
}
