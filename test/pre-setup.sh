#!/bin/bash

set -x
set -e

cd ..

curl 'https://gitlab.wikimedia.org/repos/releng/cli/-/jobs/254914/artifacts/download' > mw.zip
unzip -j mw.zip bin/mw
mv mw /usr/local/bin/mw
chmod +x /usr/local/bin/mw
rm mw.zip

git clone --depth 1 https://github.com/wikimedia/mediawiki.git /srv/mediawiki
cp -r testwikifarm /srv/mediawiki/extensions/

cd /srv/mediawiki
ln -s ./extensions/testwikifarm/LocalSettings.php .
mw docker mediawiki create --no-interaction
