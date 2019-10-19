require 'restclient'
require 'csv'
require 'ruby-progressbar'
  using ProgressBar::Refinements::Enumerator

# button click
# curl 'https://www.facebook.com/ads/library/report/v2/download/?report_ds=2019-10-14&country=US&time_preset=lifelong' -H 'sec-fetch-mode: cors' -H 'origin: https://www.facebook.com' -H 'accept-encoding: gzip, deflate, br' -H 'accept-language: en-US,en;q=0.9' -H 'cookie: sb=IoBAXI4q7lWEnIkrLfNNYAzI; datr=IoBAXF3vHAqH44Jh5cQXSeud; ; m_pixel_ratio=1; _fbp=fb.1.1561476915026.1936011854; dpr=0.800000011920929; fr=0p6uXMvLrsGk8crVX.AWXzpkmvjYXg4x1O5D96S0j2UuU.BcPLZ9.cE.F2f.0.0.Bdp5DS.AWVryIfF; wd=2400x573; act=1571275280179%2F12' -H 'user-agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/77.0.3865.90 Safari/537.36' -H 'viewport-width: 2400' -H 'content-type: application/x-www-form-urlencoded' -H 'accept: */*' -H 'referer: https://www.facebook.com/ads/library/report/?source=archive-landing-page&country=US' -H 'authority: www.facebook.com' -H 'sec-fetch-site: same-origin' --data '__user=0&__a=1&__dyn=7xeUmBwjbgydwn8K4osBWo5O12wAxu13wqojyUW3qi2K7E2gzEeUhwmU8o3ex60DU4m0nCq1ewcG0KEswDwb62W2y11xmfz81bo4aV8y1vw4UgtyU8830waW588EtwKwrUuwl8&__csr=&__req=h&__be=1&__pc=PHASED%3ADEFAULT&dpr=1&__rev=1001303917&__s=xnvtiu%3A2km4hi%3A0apt3i&__hsi=6748575805050235210-0&lsd=AVpGdTM9&jazoest=2652&__spin_r=1001303917&__spin_b=trunk&__spin_t=1571275248' --compressed
# resp: 
# for (;;);{"__ar":1,"payload":{"uri":"https:\/\/scontent.fatl1-1.fna.fbcdn.net\/v\/t39.22812-6\/73523154_439355123354482_6936595521339392000_n.zip\/FacebookAdLibraryReport_2019-10-13_US_lifelong.zip?_nc_cat=109&_nc_oc=AQnfBQCxEbzdAvWxPrd6tb2N7H1Cw0V1oXVQ7z1_9zFSxIz7H6r-58RjDH1kh6_w5oA8FV_GIIriP7lNZedC3q2k&_nc_ht=scontent.fatl1-1.fna&oh=d1ec76c02eb5bd4924b88f912fcaa2a0&oe=5E2156B1"},"jsmods":{"require":[["ServerRedirect","redirectPageTo",[],["https:\/\/scontent.fatl1-1.fna.fbcdn.net\/v\/t39.22812-6\/73523154_439355123354482_6936595521339392000_n.zip\/FacebookAdLibraryReport_2019-10-13_US_lifelong.zip?_nc_cat=109&_nc_oc=AQnfBQCxEbzdAvWxPrd6tb2N7H1Cw0V1oXVQ7z1_9zFSxIz7H6r-58RjDH1kh6_w5oA8FV_GIIriP7lNZedC3q2k&_nc_ht=scontent.fatl1-1.fna&oh=d1ec76c02eb5bd4924b88f912fcaa2a0&oe=5E2156B1",false,false]]]},"js":["h5pkU","90bAh"],"bootloadable":{},"resource_map":{"h5pkU":{"type":"js","src":"https:\/\/static.xx.fbcdn.net\/rsrc.php\/v3ikW24\/yl\/l\/en_US\/PzkBlmsv0eY.js?_nc_x=Ij3Wp8lg5Kz"},"90bAh":{"type":"js","src":"https:\/\/static.xx.fbcdn.net\/rsrc.php\/v3\/yo\/r\/bicL1eSbHSZ.js?_nc_x=Ij3Wp8lg5Kz"}},"ixData":{},"bxData":{},"gkxData":{},"qexData":{},"lid":"6748575928253766638"}

# CSV link:

# curl 'https://scontent.fatl1-1.fna.fbcdn.net/v/t39.22812-6/73523154_439355123354482_6936595521339392000_n.zip/FacebookAdLibraryReport_2019-10-13_US_lifelong.zip?_nc_cat=109&_nc_oc=AQnfBQCxEbzdAvWxPrd6tb2N7H1Cw0V1oXVQ7z1_9zFSxIz7H6r-58RjDH1kh6_w5oA8FV_GIIriP7lNZedC3q2k&_nc_ht=scontent.fatl1-1.fna&oh=d1ec76c02eb5bd4924b88f912fcaa2a0&oe=5E2156B1' -H 'authority: scontent.fatl1-1.fna.fbcdn.net' -H 'upgrade-insecure-requests: 1' -H 'user-agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/77.0.3865.90 Safari/537.36' -H 'sec-fetch-mode: navigate' -H 'sec-fetch-user: ?1' -H 'accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3' -H 'sec-fetch-site: cross-site' -H 'referer: https://www.facebook.com/' -H 'accept-encoding: gzip, deflate, br' -H 'accept-language: en-US,en;q=0.9' --compressed


# should get the daily ones each day and also download the lifelong one each day, I guess.
# probably via a lambda and a cron?
# and a *separate* lambda that checks if it's there and notifies us in Slack.
# Page ID	Page Name	Disclaimer		

namespace :ad_archive_report do 
	task download: :environment do 
		# scrape_date:datetime s3_url:text kind:text
		# and should put on S3 too.
		filename = "/Users/jmerrill/downloads/FacebookAdLibraryReport_2019-10-13_US_lifelong/FacebookAdLibraryReport_2019-10-13_US_lifelong_advertisers.csv"
		report = AdArchiveReport.create(scrape_date: File.mtime(filename), s3_url: nil, kind: "lifelong")
	end

	task load: :environment do 

		# FacebookAdLibraryReport_2019-10-13_US_lifelong
		# FacebookAdLibraryReport_2019-10-13_US_lifelong.zip
		AdArchiveReport.where(loaded: false).each do |report|
			# TODO: download to TMP
			# TODO: unzip
			filename = "/Users/jmerrill/downloads/FacebookAdLibraryReport_2019-10-13_US_lifelong/FacebookAdLibraryReport_2019-10-13_US_lifelong_advertisers.csv"
			headers = nil
			line_count = File.foreach(filename).inject(0) {|c, line| c+1}
			progressbar = ProgressBar.create(:starting_at => 20, :total => line_count)

			open(filename, headers: true, quote_char: nil).each_with_index.with_progressbar(:total => line_count) do |line, i|
				# progressbar.increment
				if i == 0
					headers = line.chomp.split(",")
					next
				end
				begin
					row = CSV.parse_line(line.chomp, headers: headers)
				rescue CSV::MalformedCSVError
					row = CSV.parse_line(line.chomp, headers: headers, quote_char: nil)
				end
				aarp = AdArchiveReportPage.new({
					page_name: row["Page Name"],
					disclaimer: row["Disclaimer"],
					amount_spent: row["Amount Spent (USD)"],
					ads_count: row["Number of Ads in Library"]
				})
				aarp.ad_archive_report = report
				aarp.page = Page.find_by(page_id: row[row.headers[0]].to_i)
				aarp.save!
			end
			report.loaded = true
			report.save
		end
	end

end