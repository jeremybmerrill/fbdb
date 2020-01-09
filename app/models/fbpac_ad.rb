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




  MISSING_STR = "missingpaidforby"

  def as_indexed_json(options={}) # for ElasticSearch
    json = self.as_json() # TODO: this needs a lot of work, I don't know the right way to do this, presumably I'll want writablefbpacads too
#      json["topics"] = json["topics"]&.map{|topic| topic["topic"]}
    json["paid_for_by"] = MISSING_STR if (json["paid_for_by"].nil? || json["paid_for_by"].empty?) && json["created_at"] > "2018-07-01" 
    json
  end

  def clean_text
    Nokogiri::HTML(message).text.strip.downcase.gsub(/\s/, ' ').gsub(/[^a-z 0-9]/, '')
  end
end
