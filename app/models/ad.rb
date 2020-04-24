

class Ad < ApplicationRecord
    self.primary_key = 'archive_id'
    # has_one :collector_ad, primary_key: :archive_id # for the NEW collector, not existing FBPAC.
    belongs_to :payer, foreign_key: :name, primary_key: :funding_entity
    belongs_to :page, primary_key: :page_id
    has_many :impressions, primary_key: :archive_id, foreign_key: :archive_id
    default_scope { order(:archive_id) } 

    has_one  :writable_ad, primary_key: :archive_id, foreign_key: :archive_id # just a proxy
    has_one :fbpac_ad, primary_key: :ad_id, foreign_key: :id # doesn't work anymore, sadly
    
    def as_json(options={})
      preset_options = {
        include: { page: { only: :page_name },
                   payer:    { only: :name },
                   writable_ad: {topics:   { only: :topic }}
        }
      }
      if options[:include].is_a? Symbol
        options[:include] = Hash[options[:include], nil]
      end
      if !options[:include].nil? && options.has_key?(:include)
        options[:include] = preset_options[:include].deep_merge(!options.nil? && options[:include] ? options[:include] : {})
      end

      super(options).tap do |json|
        advertiser = (json["page"] || {})["page_name"]
        json["advertiser"] = advertiser if advertiser
        json["text"] = json.delete("ad_creative_body")
        json.delete("page")
        json["funding_entity"] = json["funding_entity"] || (json["payer"] || {})["name"]
        json["topics"] = json["topics"]&.map{|topic| topic["topic"]}
        json = json.delete("writable_ad") if json.has_key?("writable_ad")
        json = json.merge(json)
      end
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

    # # Exclude snapshot_url, is_active from JSON responses
    # def serializable_hash(options={})
    #   options = { 
    #       exclude: [:snapshot_url, :is_active]
    #   }.update(options)
    #   super(options)
    # end
    def text
      [ad_creative_body, ad_creative_link_caption, ad_creative_link_title, ad_creative_link_description].join(' ')
    end

    def clean_text
      # clean_text exists to get hashed. those hashes have to match with hashes from FBPAC-collected ads.
      # FBPAC ads only make it easy/possible to get the equivalent of ad_creative_body
      ad_creative_body.to_s.strip.downcase.gsub(/\s+/, ' ').gsub(/[^a-z 0-9]/, '')
    end

    def create_writable_ad!
      wad = WritableAd.new
      wad.archive_id = archive_id
      wad.page_id = page_id
      wad.save!
      wad
    end

    def create_ad_text!(wad)
      wad.text_hash = Digest::SHA1.hexdigest(clean_text)
      ad_text = AdText.find_or_create_by(text_hash: wad.text_hash)
      ad_text.text ||= text
      ad_text.search_text ||= page.page_name + " " + text
      ad_text.first_seen = [ad_text.first_seen, ad_creation_time].compact.min # set the creation time to be the earliest we've seen for this text.
      ad_text.last_seen = [ad_text.last_seen, ad_delivery_stop_time].compact.max
      ad_text.page_id ||= page_id
      ad_text.advertiser ||= page.page_name
      ad_text.paid_for_by ||= funding_entity
      ad_text.save!
      ad_text
    end


end


# select * from impressions join ads on ads.archive_id = impressions.archive_id where ads.archive_id = 625389131321564;
# Ad.joins(:ad_topics).joins(:topics).sum("coalesce(ad_topics.proportion,  cast(1.0 as double precision))")