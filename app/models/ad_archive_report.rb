class AdArchiveReport < ApplicationRecord
	default_scope{ order :scrape_date }
	has_many :ad_archive_report_pages

	
	# this is the date against which we'll do total calculations in the dashboard
	# since we don't want to use May 2018 as the date against which totals are calculated forever
	# (since that'll include all sorts of irrelevant stuff, like Beto for Texas)
	START_DATE = Date.new(2019, 11, 17) # after LAGov elex.


	def self.about_a_week_ago
		most_recent = AdArchiveReport.where(kind: "lifelong").last.scrape_date.to_date.to_s
		AdArchiveReport.unscope(:order).where(kind: "lifelong").where("scrape_date < ?", most_recent).order("abs(7 - extract(day from '#{most_recent}' - scrape_date))").first
	end

	def self.starting_point
		AdArchiveReport.unscope(:order).where(kind: "lifelong").where("scrape_date >= ?", START_DATE).order("scrape_date asc").first
	end

	def filename
		# pick a /tmp URL
		# TODO: download it from s3_url if the /tmp file doesn't exist (or is empty)
		# return the tmp url
		s3_url
	end

end
