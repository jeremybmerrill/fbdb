class WritablePage < ApplicationRecord
	belongs_to :page, primary_key: :page_id, foreign_key: :page_id, optional: true

  has_many :ad_texts, primary_key: :page_id, foreign_key: :page_id
  has_many :ads, primary_key: :page_id, foreign_key: :page_id

end
