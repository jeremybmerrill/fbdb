class Topic < ApplicationRecord
	has_many :ads, through: :ad_topics
	has_many :ad_topics
end
