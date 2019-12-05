class AdArchiveReportPage < ApplicationRecord
	belongs_to :page, foreign_key: :page_id, primary_key: :page_id, optional: true
	belongs_to :writable_page, foreign_key: :page_id, primary_key: :page_id, optional: true
	belongs_to :ad_archive_report
    default_scope { order(:ad_archive_report_id) } 

    def has_disclaimer?
    	disclaimer != "These ads ran without a disclaimer"
    end	

    def ad_library_url
		url = "https://www.facebook.com/ads/library/?active_status=all&ad_type=political_and_issue_ads&country=US&impression_search_field=has_impressions_lifetime&q=#{page_name}"
		url += "&disclaimer_texts[0]=#{disclaimer}" if has_disclaimer?
		url
    end
end
