class AdTopic < ApplicationRecord
	belongs_to :topic
	belongs_to :ad_text

	def as_json
		topic
	end
end
