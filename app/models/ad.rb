class Ad < ApplicationRecord
    self.primary_key = 'archive_id'
    # has_one :collector_ad, primary_key: :archive_id # for the NEW collector, not existing FBPAC.
    belongs_to :payer, foreign_key: :name, primary_key: :funding_entity
    belongs_to :page, primary_key: :page_id
    has_many :impressions, primary_key: :archive_id, foreign_key: :ad_archive_id
    default_scope { order(:archive_id) } 

    has_many :ad_topics, primary_key: :archive_id, foreign_key: :archive_id
    has_many :topics, through: :ad_topics
    has_one  :writable_ad, primary_key: :archive_id, foreign_key: :archive_id # just a proxy

    has_one :fbpac_ad, primary_key: :ad_id, foreign_key: :id
    
    include Elasticsearch::Model
    index_name Rails.application.class.module_parent_name.underscore
    document_type self.name.downcase
    def as_indexed_json(options={}) # for ElasticSearch
      json = self.as_json(
        include: { page: { only: :page_name },
                   payer:    { only: :name },
                   topics:   { only: :topic },
                   fbpac_ad: {only: :targetings }
                 })
      puts json["topics"].inspect if json["topics"]
      json["topics"] = json["topics"]&.map{|topic| topic["topic"]}
      json
    end

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
    #   writable_ad.topics
    # end

    # def topic_writable_ads
    #   writable_ad.topic_writable_ads
    # end   

    # TODO: Exclude snapshot_url, is_active from JSON responses
      def serializable_hash(options={})
        options = { 
            exclude: [:snapshot_url, :is_active]
        }.update(options)
        super(options)
      end

end


# select * from impressions join ads on ads.archive_id = impressions.ad_archive_id where ads.archive_id = 625389131321564;
# Ad.joins(:ad_topics).joins(:topics).sum("coalesce(ad_topics.proportion,  cast(1.0 as double precision))")