#!/bin/bash

mw docker mediawiki exec -- test -d /var/www/html/w/extensions/AntiSpoof || mw docker mediawiki get-code --extension AntiSpoof
mw docker mediawiki exec -- test -d /var/www/html/w/extensions/CentralAuth || mw docker mediawiki get-code --extension CentralAuth
mw docker mediawiki exec -- test -d /var/www/html/w/extensions/Wikibase || mw docker mediawiki get-code --extension Wikibase
mw docker mediawiki exec -- test -d /var/www/html/w/extensions/WikibaseLexeme || mw docker mediawiki get-code --extension WikibaseLexeme

# Basic set up:

mw docker mysql create
mw docker mediawiki create

# Create the CentralAuth database and tables:
mw docker mediawiki exec -- /wait-for-it.sh -h mysql -p 3306
mw docker mysql mysql -- -e 'CREATE DATABASE centralauth;'
mw docker mysql mysql -- --database centralauth -e "$(mw docker mediawiki exec -- cat /var/www/html/w/extensions/AntiSpoof/sql/mysql/tables-generated.sql)"
mw docker mysql mysql -- --database centralauth -e "$(mw docker mediawiki exec -- cat /var/www/html/w/extensions/CentralAuth/schema/mysql/tables-generated.sql)"
mw docker mysql mysql -- --database centralauth -e "$(mw docker mediawiki exec -- grep -ozP '(?s)CREATE TABLE .{0,10}objectcache.*?;' /var/www/html/w/maintenance/tables-generated.sql | tr -d '\000' )"

# To create the wikis:

mw docker mediawiki install --dbtype mysql --dbname=dewiki
mw docker mediawiki install --dbtype mysql --dbname=enwiki
mw docker mediawiki install --dbtype mysql --dbname=metawiki
mw docker mediawiki install --dbtype mysql --dbname=wikidatawiki

# Do the CentralAuth migrations:

mw docker mediawiki foreachwiki CentralAuth:migratePass0
mw docker mediawiki foreachwiki CentralAuth:migratePass1

# Wikibase set up:

mw docker mediawiki foreachwiki addSite -- --interwiki-id de --language de --pagepath "http://dewiki.mediawiki.mwdd.localhost:$(mw docker env get PORT)/wiki/\$1" \
	--filepath "http://dewiki.mediawiki.mwdd.localhost:$(mw docker env get PORT)/w/\$1" dewiki wikipedia
mw docker mediawiki foreachwiki addSite -- --interwiki-id en --language en --pagepath "http://enwiki.mediawiki.mwdd.localhost:$(mw docker env get PORT)/wiki/\$1" \
	--filepath "http://enwiki.mediawiki.mwdd.localhost:$(mw docker env get PORT)/w/\$1" enwiki wikipedia
mw docker mediawiki foreachwiki addSite -- --interwiki-id meta --language en --pagepath "http://metawiki.mediawiki.mwdd.localhost:$(mw docker env get PORT)/wiki/\$1" \
	--filepath "http://metawiki.mediawiki.mwdd.localhost:$(mw docker env get PORT)/w/\$1" metawiki meta
mw docker mediawiki foreachwiki addSite -- --interwiki-id wd --language en --pagepath "http://wikidatawiki.mediawiki.mwdd.localhost:$(mw docker env get PORT)/wiki/\$1" \
	--filepath "http://wikidatawiki.mediawiki.mwdd.localhost:$(mw docker env get PORT)/w/\$1" wikidatawiki wikidata

mw docker mediawiki foreachwiki sql.php -- --query "INSERT INTO interwiki VALUES('de', 'http://dewiki.mediawiki.mwdd.localhost:$(mw docker env get PORT)/wiki/\$1', 'http://dewiki.mediawiki.mwdd.localhost:$(mw docker env get PORT)/w/\$1', 'dewiki', 1, 0);"
mw docker mediawiki foreachwiki sql.php -- --query "INSERT INTO interwiki VALUES('en', 'http://enwiki.mediawiki.mwdd.localhost:$(mw docker env get PORT)/wiki/\$1', 'http://enwiki.mediawiki.mwdd.localhost:$(mw docker env get PORT)/w/\$1', 'enwiki', 1, 0);"
mw docker mediawiki foreachwiki sql.php -- --query "INSERT INTO interwiki VALUES('meta', 'http://metawiki.mediawiki.mwdd.localhost:$(mw docker env get PORT)/wiki/\$1', 'http://metawiki.mediawiki.mwdd.localhost:$(mw docker env get PORT)/w/\$1', 'metawiki', 1, 0);"
mw docker mediawiki foreachwiki sql.php -- --query "INSERT INTO interwiki VALUES('wd', 'http://wikidatawiki.mediawiki.mwdd.localhost:$(mw docker env get PORT)/wiki/\$1', 'http://wikidatawiki.mediawiki.mwdd.localhost:$(mw docker env get PORT)/w/\$1', 'wikidatawiki', 1, 0);"

