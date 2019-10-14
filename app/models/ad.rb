class Ad < ApplicationRecord
	self.primary_key = 'archive_id'
	has_one :collector_ad, primary_key: :archive_id
	belongs_to :payer, foreign_key: :name, primary_key: :funding_entity
	belongs_to :page, primary_key: :page_id
	has_many :impressions, primary_key: :archive_id, foreign_key: :ad_archive_id
	default_scope { order(:archive_id) } 

	has_many :ad_topics, primary_key: :archive_id, foreign_key: :archive_id
	has_many :topics, through: :ad_topics
	has_one  :writable_ad, primary_key: :archive_id, foreign_key: :archive_id # just a proxy

	has_one :fbpac_ad, primary_key: :ad_id, foreign_key: :id

	def min_spend
		impressions.first.min_spend
	end

	def min_impressions
		impressions.first.min_impressions
	end

	def domain
		# has to come from collector ads or AdLibrary ads.
	end

	# def topics
	# 	writable_ad.topics
	# end

	# def topic_writable_ads
	# 	writable_ad.topic_writable_ads
	# end	

	# TODO: Exclude snapshot_url, is_active from JSON responses

end


# select * from impressions join ads on ads.archive_id = impressions.ad_archive_id where ads.archive_id = 625389131321564;
# Ad.joins(:ad_topics).joins(:topics).sum("coalesce(ad_topics.proportion,  cast(1.0 as double precision))")