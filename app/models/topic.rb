class Topic < ApplicationRecord
	has_many :ads, through: :ad_topics
	has_many :ad_topics

  def as_json(options)
    super(options).without("created_at", "updated_at")
  end


end
