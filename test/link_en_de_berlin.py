#!/bin/python3

import mwclient

site = mwclient.Site(
    'wikidatawiki.mediawiki.local.wmftest.net:8080/', scheme='http', path='/w/')

site.post('wblinktitles', token=site.get_token('edit'), fromsite="dewiki",
          tosite="enwiki", fromtitle="Berlin", totitle="Berlin")
