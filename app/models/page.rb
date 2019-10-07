class Page < ApplicationRecord
	has_many :ads, primary_key: :page_id
end