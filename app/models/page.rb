class Page < ApplicationRecord
	self.primary_key = :page_id
	has_many :ads, primary_key: :page_id
	has_many :fbpac_ads, primary_key: :advertiser
	has_one  :writable_page, primary_key: :page_id, foreign_key: :page_id # just a proxy
	has_many :ad_archive_report_pages, primary_key: :page_id, foreign_key: :page_id
	def min_spend
		ads.joins(:impressions).group(:archive_id).sum(:min_spend).values.reduce(&:+)
	end
	def max_spend
		ads.joins(:impressions).group(:archive_id).sum(:max_spend).values.reduce(&:+)
	end

	def payers
		Payer.where(name: ads.unscope(:order).select("distinct funding_entity"))
	end

	def min_impressions
		#ads.joins(:impressions).group(:ad_archive_id).max(:crawl_date).sum(:min_impressions)
		puts "needs to limit to just the most recent in each group"
		ads.joins(:impressions).group(:archive_id).sum(:min_impressions).values.reduce(&:+)
	end

	def topic_breakdown
		if ads.count > 1
			breakdown = Hash[*ads.unscope(:order).joins(writable_ad: [{:ad_text => [{ad_topics: :topic}]}]).select("topic, sum(coalesce(ad_topics.proportion, cast(1.0 as double precision))) as proportion").group(:topic).map{|a| [a.topic, a.proportion]}.flatten]
		else
			breakdown = Hash[*fbpac_ads.unscope(:order).joins(writable_ad: [{:ad_text => [{ad_topics: :topic}]}]).select("topic, sum(coalesce(ad_topics.proportion, cast(1.0 as double precision))) as proportion").group(:topic).map{|a| [a.topic, a.proportion]}.flatten]
		end
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

	def targeting_methods
        individual_methods = FbpacAd.connection.execute("select target, segment, count(*) as count from (select jsonb_array_elements(targets)->>'segment' as segment, jsonb_array_elements(targets)->>'target' as target from fbpac_ads WHERE #{Ad.send(:sanitize_sql_for_conditions, ["fbpac_ads.advertiser = ?", [page_name]] )}) q  group by segment, target order by count desc").to_a
        combined_methods = FbpacAd.unscope(:order).where(advertiser: page_name).group(:targets).count.to_a.sort_by{|a, b| -b}
        {individual_methods: individual_methods, combined_methods: combined_methods}
    end



	def to_s
		"#<Page id=#{page_id} name=#{page_name}>"
	end

end