# testwikifarm
Configuration and shell scripts to set up a farm of test wikis using the mw cli.

# Installation
Clone MediaWiki and clone this repo into its extensions dir. Then create a relative symlink to this `LocalSettings.php` from the MediaWiki root folder. Finally set up [`mw` cli](https://www.mediawiki.org/wiki/Cli) and run `setup.sh`.

# Environment for browser tests (for wikidatawiki)

```bash
export MW_SERVER=http://wikidatawiki.mediawiki.mwdd.localhost:8080/
export MW_SCRIPT_PATH=/w
export MEDIAWIKI_USER=Admin
export MEDIAWIKI_PASSWORD=mwddpassword
```
