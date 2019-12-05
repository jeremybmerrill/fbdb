class WritablePage < ApplicationRecord
	belongs_to :page, primary_key: :page_id, foreign_key: :page_id, optional: true
end
