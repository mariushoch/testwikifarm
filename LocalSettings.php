<?php
require_once '/mwdd/MwddSettings.php';

$wgDebugToolbar = true;
require_once "$IP/includes/DevelopmentSettings.php";
error_reporting( ~E_DEPRECATED );
$wgMainCacheType = CACHE_MEMCACHED;

wfLoadSkin('Vector');
wfLoadExtension('AntiSpoof');

if ( $wgDBname === 'dewiki' ) {
	$wgLanguageCode = 'de';
}

/**
 * CentralAuth / wgConf
 */
wfLoadExtension('CentralAuth');
$wgCentralAuthAutoMigrate = true;
$wgCentralAuthAutoMigrateNonGlobalAccounts = true;
$wgCentralAuthCookies = true;
$wgCentralAuthDatabase = 'centralauth';
$wgVirtualDomainsMapping['virtual-centralauth'] = [ 'db' => $wgCentralAuthDatabase ];
$wgCentralAuthSessionCacheType = CACHE_MEMCACHED;
$wgCentralAuthAutoLoginWikis = [
	'dewiki.mediawiki.mwdd.localhost:8080' => 'dewiki',
	'enwiki.mediawiki.mwdd.localhost:8080' => 'enwiki',
	'metawiki.mediawiki.mwdd.localhost:8080' => 'metawiki',
	'wikidatawiki.mediawiki.mwdd.localhost:8080' => 'wikidatawiki' 
];
$wgCentralAuthLoginWiki = 'metawiki';
$wgLocalDatabases = array_values( $wgCentralAuthAutoLoginWikis );
$wgConf->wikis = $wgLocalDatabases;
$wgConf->suffixes = [ 'wiki' ];
$wgConf->localVHosts = [ 'localhost' ];
$wgConf->settings = [
	'wgServer' => [
		'dewiki' => "//dewiki.mediawiki.mwdd.localhost:8080",
		'enwiki' => "//enwiki.mediawiki.mwdd.localhost:8080",
		'metawiki' => "//metawiki.mediawiki.mwdd.localhost:8080",
		'wikidatawiki' => "//wikidatawiki.mediawiki.mwdd.localhost:8080",
	],
	'wgCanonicalServer' => [
		'dewiki' => "http://dewiki.mediawiki.mwdd.localhost:8080",
		'enwiki' => "http://enwiki.mediawiki.mwdd.localhost:8080",
		'metawiki' => "http://metawiki.mediawiki.mwdd.localhost:8080",
		'wikidatawiki' => "http://wikidatawiki.mediawiki.mwdd.localhost:8080",
	],
	'wgArticlePath' => [
		// Same on all wikis
		'default' => $wgArticlePath,
	],
];

/**
 * Wikibase
 */
wfLoadExtension( 'WikibaseLexeme' );
$repoDatabase = 'wikidatawiki';
wfLoadExtension( 'WikibaseClient', "$IP/extensions/Wikibase/extension-client.json" );
require_once "$IP/extensions/Wikibase/client/ExampleSettings.php";

$wgWBClientSettings['siteGroup'] = 'wikipedia';

wfLoadExtension( 'EntitySchema' );
$wgEntitySchemaIsRepo = $wgDBname === $repoDatabase;
if ( $wgDBname === $repoDatabase ) {
	wfLoadExtension( 'WikibaseRepository', "$IP/extensions/Wikibase/extension-repo.json" );
	require_once "$IP/extensions/Wikibase/repo/ExampleSettings.php";
	$wgWBClientSettings['siteGroup'] = 'wikidata';
} elseif ( $wgDBname === 'metawiki' ) {
	$wgWBClientSettings['siteGroup'] = 'meta';
}
$wgWBClientSettings['repoUrl'] = $wgConf->get( 'wgServer', $repoDatabase );
$wgWBClientSettings['siteLinkGroups'] = ['wikipedia', 'special'];
$wgWBClientSettings['specialSiteLinkGroups'] = ['meta', 'wikidata'];
$wgWBRepoSettings['siteLinkGroups'] = $wgWBClientSettings['siteLinkGroups'];
$wgWBRepoSettings['specialSiteLinkGroups'] = $wgWBClientSettings['specialSiteLinkGroups'];
$wgWBRepoSettings['localClientDatabases'] = array_combine( $wgLocalDatabases, $wgLocalDatabases );
$wgWBClientSettings['repoDatabase'] = $repoDatabase;
$wgWBClientSettings['injectRecentChanges'] = true;
$entitySources = [
	'wikidata' => [
		'entityNamespaces' => [
			'item' => 120,
			'property' => 122,
			'lexeme' => 146,
		],
		'repoDatabase' => 'wikidatawiki',
		'baseUri' => 'http://wikidatawiki.mediawiki.mwdd.localhost:8080/entity/',
		'rdfNodeNamespacePrefix' => 'wd',
		'rdfPredicateNamespacePrefix' => '',
		'interwikiPrefix' => 'wd',
	]
];
$wgWBClientSettings['entitySources'] = $entitySources;
$wgWBClientSettings['itemAndPropertySourceName'] = 'wikidata';
