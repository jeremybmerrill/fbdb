class AdArchiveReport < ApplicationRecord
	default_scope{ order :scrape_date }
	has_many :ad_archive_report_pages

	def self.about_a_week_ago
		most_recent = AdArchiveReport.where(kind: "lifelong").last.scrape_date.to_date.to_s
		AdArchiveReport.unscope(:order).where(kind: "lifelong").order("abs(7 - extract(day from '#{most_recent}' - scrape_date))").first
	end

	def filename
		# pick a /tmp URL
		# TODO: download it from s3_url if the /tmp file doesn't exist (or is empty)
		# return the tmp url
		s3_url
	end

end
