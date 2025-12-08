#!/bin/bash

set -x
set -e

cd ..

curl -L 'https://gitlab.wikimedia.org/api/v4/projects/16/packages/generic/mwcli/v0.29.1/mw_v0.29.1_linux_amd64' > /usr/local/bin/mw
chmod +x /usr/local/bin/mw

git clone --depth 1 https://github.com/wikimedia/mediawiki.git /srv/mediawiki
cp -r testwikifarm /srv/mediawiki/extensions/

cd /srv/mediawiki
ln -s ./extensions/testwikifarm/LocalSettings.php .

mw config set telemetry false --no-interaction
mw docker env set MEDIAWIKI_VOLUMES_CODE /srv/mediawiki
