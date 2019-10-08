class Page < ApplicationRecord
	has_many :ads, primary_key: :page_id
	has_one  :writable_page, primary_key: :page_id, foreign_key: :page_id # just a proxy

	def min_spend
		ads.joins(:impressions).group(:archive_id).sum(:min_spend).values.reduce(&:+)
	end

	def payers
		Payer.where(name: ads.unscope(:order).select("distinct funding_entity"))
	end

	# TODO advertiser spend: is this in the DB or do we have to get the Ad Archive Report?


	def min_impressions
		#ads.joins(:impressions).group(:ad_archive_id).max(:crawl_date).sum(:min_impressions)
		puts "needs to limit to just the most recent in each group"
		ads.joins(:impressions).group(:archive_id).sum(:min_impressions).values.reduce(&:+)
	end

	def topic_breakdown
		breakdown = Hash[*ads.unscope(:order).joins(:ad_topics).joins(:topics).select("topic, sum(coalesce(ad_topics.proportion, cast(1.0 as double precision))) as proportion").group(:topic).map{|a| [a.topic, a.proportion]}.flatten]
		total = breakdown.values.reduce(&:+)
		breakdown_proportions = {}
		breakdown.each do | topic, amt |
			breakdown_proportions[topic] = amt.to_f / total
		end
		breakdown_proportions
	end

	def notes=(text)
		if writable_page.nil?
			self.writable_page = WritablePage.new
		end
		writable_page.notes = text
		writable_page.save
	end

	def notes
		writable_page&.notes
	end


end