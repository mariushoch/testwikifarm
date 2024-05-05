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
	curl -v -L --fail 'http://dewiki.mediawiki.mwdd.localhost:8080/wiki/'
	curl -v -L --fail 'http://enwiki.mediawiki.mwdd.localhost:8080/wiki/'
	curl -v -L --fail 'http://metawiki.mediawiki.mwdd.localhost:8080/wiki/'
	curl -v -L --fail 'http://wikidatawiki.mediawiki.mwdd.localhost:8080/wiki/'
}
@test "mw docker mediawiki doctor" {
	sudo mw docker mediawiki doctor
}
@test "mw docker mediawiki foreachwiki runJobs" {
	sudo mw docker mediawiki foreachwiki runJobs
}
