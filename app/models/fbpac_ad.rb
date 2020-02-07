class FbpacAd < ApplicationRecord
#   belongs_to :ad, primary_key: :ad_id, foreign_key: :id # doesn't work anymore :(

  belongs_to :writable_ad, primary_key: :ad_id, foreign_key: :id
  belongs_to :ad_text, primary_key: :ad_id, foreign_key: :id

  include Elasticsearch::Model
  index_name Rails.application.class.module_parent_name.underscore + "_" + self.name.downcase
  document_type self.name.downcase
  # settings index: { number_of_shards: 1 } do
  #   mappings dynamic: 'false' do
  #     indexes :title, analyzer: 'english', index_options: 'offsets'
  #   end
  # end

  mapping dynamic: true do 
    indexes :lang, type: :keyword
    indexes :targets, type: 'nested' do
      indexes :target,  type: :keyword
      indexes :segment, type: :keyword
    end
  end


  def as_json(options={})
    # translating this schema to match the FB one as much as possible
    super.tap do |json|
      json["creation_date"] = json.delete("created_at")
      json["text"] = json.delete("message") # TODO: remove HTML tags
      json["funding_entity"] = json["paid_for_by"]
      # what if page_id doesn't exist?!
#      json["page_id"] 
      json["start_date"] = json.delete("created_at")
      json = json.merge(json.delete("writable_ad"))
    end
  end


#   MISSING_STR = "missingpaidforby"

#   def as_indexed_json(options={}) # for ElasticSearch
#     json = self.as_json() # TODO: this needs a lot of work, I don't know the right way to do this, presumably I'll want writablefbpacads too
# #      json["topics"] = json["topics"]&.map{|topic| topic["topic"]}
#     json["paid_for_by"] = MISSING_STR if (json["paid_for_by"].nil? || json["paid_for_by"].empty?) && json["creation_date"] && json["creation_date"]> "2018-07-01" 
#     json
#   end

  def text
    Nokogiri::HTML(message).text.strip
  end
  def clean_text
    text.downcase.gsub(/\s+/, ' ').gsub(/[^a-z 0-9]/, '')
  end
end
