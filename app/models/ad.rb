

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


    has_one :fbpac_ad, primary_key: :ad_id, foreign_key: :id # doesn't work anymore, sadly
    
    include Elasticsearch::Model
    index_name Rails.application.class.module_parent_name.underscore + "_" + self.name.downcase
    document_type self.name.downcase
    mapping dynamic: true do 
      indexes :topics, type: :keyword
    end

    def as_json(options={})
      # translating this schema to match the FBPAC one as much as possible
      preset_options = {
        include: { page: { only: :page_name },
                   payer:    { only: :name },
                   topics:   { only: :topic } 
        }
      }
      if options[:include].is_a? Symbol
        options[:include] = Hash[options[:include], nil]
      end
      options[:include] = preset_options[:include].deep_merge(!options.nil? && options[:include] ? options[:include] : {})
      super(options).tap do |json|
        json["advertiser"] = (json["page"] || {})["page_name"]
        json.delete("page")
        json["funding_entity"] = json["funding_entity"] || (json["payer"] || {})["name"]
        json["topics"] = json["topics"]&.map{|topic| topic["topic"]}
        json = json.delete("writable_ad").merge(json)
      end
    end

    # def as_indexed_json(options={}) # for ElasticSearch
    #   json = self.as_json
    #   json
    # end

    def min_spend
        impressions.first.min_spend
    end

    def min_impressions
        impressions.first.min_impressions
    end

    def domain
        # has to come from collector ads or AdLibrary ads.
    end

    # TODO: Exclude snapshot_url, is_active from JSON responses
    def serializable_hash(options={})
      options = { 
          exclude: [:snapshot_url, :is_active]
      }.update(options)
      super(options)
    end


    def clean_text
      text.strip.downcase.gsub(/\s+/, ' ').gsub(/[^a-z 0-9]/, '')
    end
end


# select * from impressions join ads on ads.archive_id = impressions.ad_archive_id where ads.archive_id = 625389131321564;
# Ad.joins(:ad_topics).joins(:topics).sum("coalesce(ad_topics.proportion,  cast(1.0 as double precision))")