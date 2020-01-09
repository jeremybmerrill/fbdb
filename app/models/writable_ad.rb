class WritableAd < ApplicationRecord
	belongs_to :ad, primary_key: :archive_id, foreign_key: :archive_id, optional: true
  belongs_to :ad_text, primary_key: :text_hash, foreign_key: :text_hash, optional: true
  belongs_to :fbpac_ad, primary_key: :id, foreign_key: :ad_id, optional: true
#  belongs_to :collector_ad

end
