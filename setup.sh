#!/bin/bash

set -x
set -e

# Create the MySQL container
mw docker mysql create --no-interaction

# Create the Memcached container
mw docker memcached create --no-interaction

# Create the ElasticSearch container
mw docker elasticsearch create --no-interaction

# Download extensions and skins
mw docker mediawiki get-code --use-github --gerrit-interaction-type http --skin MinervaNeue || true
mw docker mediawiki get-code --use-github --gerrit-interaction-type http --skin Vector || true
mw docker mediawiki get-code --use-github --gerrit-interaction-type http --extension AntiSpoof || true
mw docker mediawiki get-code --use-github --gerrit-interaction-type http --extension CentralAuth || true
mw docker mediawiki get-code --use-github --gerrit-interaction-type http --extension Wikibase || true
mw docker mediawiki get-code --use-github --gerrit-interaction-type http --extension WikibaseLexeme || true
mw docker mediawiki get-code --use-github --gerrit-interaction-type http --extension EntitySchema || true
mw docker mediawiki get-code --use-github --gerrit-interaction-type http --extension Elastica || true
mw docker mediawiki get-code --use-github --gerrit-interaction-type http --extension CirrusSearch || true
mw docker mediawiki get-code --use-github --gerrit-interaction-type http --extension WikibaseCirrusSearch || true
mw docker mediawiki get-code --use-github --gerrit-interaction-type http --extension Scribunto || true
mw docker mediawiki get-code --use-github --gerrit-interaction-type http --extension MobileFrontend || true
mw docker mediawiki get-code --use-github --gerrit-interaction-type http --extension BetaFeatures || true
mw docker mediawiki get-code --use-github --gerrit-interaction-type http --extension UniversalLanguageSelector || true

# XDebug env, per https://www.mediawiki.org/wiki/Cli/guide/Docker-Development-Environment/MediaWiki#XDebug
command -v ip >/dev/null && mw docker env set MEDIAWIKI_XDEBUG_CONFIG "client_host=$(ip route list default | grep -oP '(?<=src )[0-9\.]+')"

# Create the MediaWiki container, run composer update
mw docker mediawiki create --no-interaction
mw docker mediawiki exec -- test -f /var/www/html/w/composer.local.json || mw docker mediawiki exec -- cp /var/www/html/w/composer.local.json-sample /var/www/html/w/composer.local.json
mw docker mediawiki composer update

# Create the CentralAuth database and tables:
mw docker mediawiki exec -- /wait-for-it.sh -h mysql -p 3306
mw docker mysql mysql -- -e 'CREATE DATABASE centralauth;'
mw docker mysql mysql -- --database centralauth -e "$(mw docker mediawiki exec -- cat /var/www/html/w/extensions/AntiSpoof/sql/mysql/tables-generated.sql)"
mw docker mysql mysql -- --database centralauth -e "$(mw docker mediawiki exec -- cat /var/www/html/w/extensions/CentralAuth/schema/mysql/tables-generated.sql)"

# Create a central centralauth.objectcache table
mw docker mysql mysql -- --database centralauth -e "$(mw docker mediawiki exec -- grep -ozP '(?s)CREATE TABLE .{0,10}objectcache.*?;' /var/www/html/w/sql/mysql/tables-generated.sql | tr -d '\000' )"

# Create the wikis:
mw docker mediawiki install --dbtype mysql --dbname=dewiki
mw docker mediawiki install --dbtype mysql --dbname=enwiki
mw docker mediawiki install --dbtype mysql --dbname=metawiki
mw docker mediawiki install --dbtype mysql --dbname=wikidatawiki

# Do the CentralAuth migrations:
mw docker mediawiki foreachwiki CentralAuth:migratePass0
mw docker mediawiki mwscript CentralAuth:migratePass1 -- --wiki metawiki # This only needs to run once

# Init the CirrusSearch indexes:
mw docker mediawiki foreachwiki CirrusSearch:UpdateSearchIndexConfig
mw docker mediawiki foreachwiki CirrusSearch:ForceSearchIndex.php -- --skipLinks --indexOnSkip
mw docker mediawiki foreachwiki CirrusSearch:ForceSearchIndex.php -- --skipParse

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

