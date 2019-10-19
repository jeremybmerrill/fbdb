class AdArchiveReport < ApplicationRecord
	default_scope{ order :scrape_date }
	has_many :ad_archive_report_pages
end
