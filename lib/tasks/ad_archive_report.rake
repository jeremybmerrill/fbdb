require 'restclient'
require 'csv'
require 'ruby-progressbar'
require 'date'
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
# Page ID   Page Name   Disclaimer      

namespace :ad_archive_report do 
    task download_lifelong: :environment do 
        # scrape_date:datetime s3_url:text kind:text
        # and should put on S3 too.
        require 'selenium'
        require 'webdrivers'
        options = Selenium::WebDriver::Chrome::Options.new
        options.add_argument('--headless')
        download_path = Rails.env.production? ? "/home/ubuntu/fbadlibrary/" : "/Users/jmerrill/code/fbadlibrary/"
        FileUtils.mkdir_p(download_path)
        options.add_preference(:download,
                          directory_upgrade: true,
                          prompt_for_download: false,
                          default_directory: download_path)

        driver = Selenium::WebDriver.for :chrome, options: options 
        bridge = driver.send(:bridge)
        path = '/session/:session_id/chromium/send_command'
        path[':session_id'] = bridge.session_id
        bridge.http.call(:post, path, cmd: 'Page.setDownloadBehavior',
                         params: {
                             behavior: 'allow',
                             downloadPath: download_path
                         })

        driver.navigate.to("https://www.facebook.com/ads/library/report/?source=archive-landing-page&country=US")
        all_dates_btn = driver.find_elements(css: 'span.label').find{|btn| btn.text == "All Dates"}
        all_dates_btn.click

        download_button = driver.find_element(css: 'div[data-testid="download_button"]')
        download_button.click

        sleep 10 # time to *actually* download it.

        filename = Dir[download_path + "FacebookAdLibraryReport_*_US_lifelong.zip"].sort_by{|f| File.mtime(f)}.last
        # date = Date.parse(File.basename(filename).split("_")[1])
        # # report = AdArchiveReport.create(scrape_date: date, s3_url: filename, kind: "lifelong")
    end

    task download_daily: :environment do 
        # scrape_date:datetime s3_url:text kind:text
        # and should put on S3 too.
        require 'selenium'
        require 'webdrivers'
        options = Selenium::WebDriver::Chrome::Options.new
        options.add_argument('--headless')
        download_path = Rails.env.production? ? "/home/ubuntu/fbadlibrary/" : "/Users/jmerrill/code/fbadlibrary/"
        FileUtils.mkdir_p(download_path)
        options.add_preference(:download,
                          directory_upgrade: true,
                          prompt_for_download: false,
                          default_directory: download_path)

        driver = Selenium::WebDriver.for :chrome, options: options 
        bridge = driver.send(:bridge)
        path = '/session/:session_id/chromium/send_command'
        path[':session_id'] = bridge.session_id
        bridge.http.call(:post, path, cmd: 'Page.setDownloadBehavior',
                         params: {
                             behavior: 'allow',
                             downloadPath: download_path
                         })
        driver.navigate.to("https://www.facebook.com/ads/library/report/?source=archive-landing-page&country=US")

        download_button = driver.find_element(css: 'div[data-testid="download_button"]')
        download_button.click

        sleep 10 # time to *actually* download it.

        filename = Dir[download_path + "FacebookAdLibraryReport_*_US_yesterday.zip"].sort_by{|f| File.mtime(f)}.last
        # date = Date.parse(File.basename(filename).split("_")[1])
        # report = AdArchiveReport.create(scrape_date: date, s3_url: filename, kind: "yesterday")

        # TODO: should have a unique index on the kind and scrapedate
    end

    REPORT_TYPES = ["lifelong", "yesterday", "last_30_days", "last_7_days", "last_90_days"]
    task manually_add_report: :environment do 
        filenames = [
                    "/Users/jmerrill/code/fbadlibrary/FacebookAdLibraryReport_2019-09-02_US_yesterday/FacebookAdLibraryReport_2019-09-02_US_yesterday_advertisers.csv",
                    "/Users/jmerrill/code/fbadlibrary/FacebookAdLibraryReport_2019-09-02_US_lifelong/FacebookAdLibraryReport_2019-09-02_US_lifelong_advertisers.csv",
                    "/Users/jmerrill/code/fbadlibrary/FacebookAdLibraryReport_2019-10-13_US_lifelong/FacebookAdLibraryReport_2019-10-13_US_lifelong_advertisers.csv",
                    "/Users/jmerrill/code/fbadlibrary/United States_FacebookAdLibraryReport_2019-10-15_US_lifelong/FacebookAdLibraryReport_2019-10-15_US_lifelong_advertisers.csv",
                    "/Users/jmerrill/code/fbadlibrary/FacebookAdLibraryReport_2019-10-17_US_lifelong/FacebookAdLibraryReport_2019-10-17_US_lifelong_advertisers.csv",
                    "/Users/jmerrill/code/fbadlibrary/FacebookAdLibraryReport_2019-10-19_US_yesterday/FacebookAdLibraryReport_2019-10-19_US_yesterday_advertisers.csv",
                    "/Users/jmerrill/code/fbadlibrary/FacebookAdLibraryReport_2019-10-20_US_lifelong/FacebookAdLibraryReport_2019-10-20_US_lifelong_advertisers.csv",
                    "/Users/jmerrill/code/fbadlibrary/FacebookAdLibraryReport_2019-10-20_US_yesterday/FacebookAdLibraryReport_2019-10-20_US_yesterday_advertisers.csv",
                ]
        filenames.each do |filename|
            date = Date.parse(File.basename(filename).split("_")[-4])
            report = AdArchiveReport.find_or_create_by(scrape_date: date, s3_url: filename, kind: REPORT_TYPES.find{|n| File.basename(filename).include?(n)})
        end
    end

    task add_reports: :environment do 
        download_path = Rails.env.production? ? "/home/ubuntu/fbadlibrary/" : "/Users/jmerrill/code/fbadlibrary/"
        filenames = Dir[download_path + "*FacebookAdLibraryReport_*.zip"]
        filenames.each do |filename|
            dest = filename.gsub(".zip", '')
            `unzip -n -d "#{dest}" "#{filename}"`
            filename = Dir[File.join(dest, "FacebookAdLibraryReport*advertisers.csv")].first
            date = Date.parse(File.basename(filename).split("_")[-4])
            report = AdArchiveReport.find_or_create_by(scrape_date: date, s3_url: filename, kind: REPORT_TYPES.find{|n| File.basename(filename).include?(n)})
        end
    end

    task load: :environment do 

        # FacebookAdLibraryReport_2019-10-13_US_lifelong
        # FacebookAdLibraryReport_2019-10-13_US_lifelong.zip
        # FacebookAdLibraryReport_2019-10-19_US_yesterday.zip

        AdArchiveReport.where(loaded: false).each do |report|
            puts "loading #{report.scrape_date} #{report.kind} report"
            headers = nil
            line_count = CSV.open(report.filename, headers: true, liberal_parsing: true){|csv| csv.to_a.size }
            progressbar = ProgressBar.create(:starting_at => 20, :total => line_count)
            puts line_count

            CSV.open(report.filename, headers: true, liberal_parsing: true).each_with_index do |row, i|
                progressbar.increment

                payer = Payer.find_or_create_by(name: row["Disclaimer"])



                aarp = AdArchiveReportPage.find_or_initialize_by({
                    ad_archive_report_id: report.id,
                    page_id: row[row.headers[0]].to_i,
                    disclaimer: row["Disclaimer"]
                })
                aarp.page_name =  row["Page Name"]
                aarp.disclaimer = row["Disclaimer"]
                aarp.amount_spent =  row["Amount Spent (USD)"].to_i
                aarp.ads_count =  row["Number of Ads in Library"].to_i
                aarp.save
            end
            report.loaded = true
            report.save
        end
    end

    MINIMUM_NEW_ADVERTISER_ALERT_AMOUNT = 1000
    MINIMUM_EXISTING_ADVERTISER_ALERT_AMOUNT = 10000

    task bigspenders: :environment do 
        BigSpender.delete_all
        current_report = AdArchiveReport.where(kind: "lifelong").last
        previous_report = AdArchiveReport.about_a_week_ago

        puts "comparing #{current_report.scrape_date} to #{previous_report.scrape_date}"

        days_diff = (current_report.scrape_date.to_date - previous_report.scrape_date.to_date).to_i

        previous_report_page_ids = Set.new(previous_report.ad_archive_report_pages.select(:page_id).pluck(:id))
        # .pluck(:id)
        current_report.ad_archive_report_pages.pluck(:page_id, :amount_spent, :id).each do |page_id, aarp_amount_spent, aarp_id|
            is_new = !previous_report_page_ids.include?(page_id)
            if is_new
                amount_spent = aarp_amount_spent
            else
                prev_aarp = AdArchiveReportPage.find_by(ad_archive_report_id: previous_report.id, page_id: page_id)
                amount_spent = aarp_amount_spent - prev_aarp.amount_spent
            end

            if (is_new && amount_spent > MINIMUM_NEW_ADVERTISER_ALERT_AMOUNT) || (!is_new && amount_spent > MINIMUM_EXISTING_ADVERTISER_ALERT_AMOUNT)
                biggie = BigSpender.create!(
                    ad_archive_report_id: current_report.id, 
                    previous_ad_archive_report_id: previous_report.id,
                    ad_archive_report_page_id: aarp_id,
                    page_id: page_id,
                    spend_amount: amount_spent,
                    duration_days: days_diff,
                    is_new: is_new
                ) 
                puts biggie
            end
        end
    end
end