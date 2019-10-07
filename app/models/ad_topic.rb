class AdTopic < ApplicationRecord
	belongs_to :topic
	belongs_to :ad, foreign_key: :archive_id, primary_key: :archive_id
end
