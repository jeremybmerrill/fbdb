# Database for Facebook ads

This is a repo for a dashboard for Facebook ads (and perhaps other online political content) built for reporters, by Quartz. It doesn't live on the web yet. There will eventually be a way for reporters to get access to it, but there isn't yet.

TODOs:
- add payer_id column on AdArchiveReportPage
- stop keeping page_name and disclaimer on AdArchiveReportPage (to save space).


how to load in Elasticsearch:
	rake environment elasticsearch:import:model CLASS='Ad'
	rake environment elasticsearch:import:model CLASS='FbpacAd'



---
example searches that should work.
http://localhost:3000/ads/search.json?no_payer=true
http://localhost:3000/ads/search.json?search=warren iowa
http://localhost:3000/ads/search.json?search=warren iowa&page=2

http://localhost:3000/ads/search.json?search=goldco
http://localhost:3000/ads/search.json?search=goldco&no_payer=true
http://localhost:3000/ads/search.json?search=warren iowa&publish_date=2019-12-15

http://localhost:3000/ads/search.json?search=warren iowa&lang=fr-CA # note that not ALL elements have to be fr-CA, some ads may have been seen by people in multiple locales


http://localhost:3000/ads/search.json?targeting=[[%22MinAge%22,59],%20[%22Interest%22,%20%22Sean%20Hannity%22]]


http://localhost:3000/ads/search.json?topic_id=11
http://localhost:3000/ads/search.json?poliprob=[0,70]