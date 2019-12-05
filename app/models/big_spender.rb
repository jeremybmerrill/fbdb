class BigSpender < ApplicationRecord
	belongs_to :ad_archive_report
	belongs_to :page, optional: true
	belongs_to :ad_archive_report_page

	belongs_to :writable_page, optional: true, primary_key: :page_id, foreign_key: :page_id

	def to_s
		aarp = self.ad_archive_report_page
		"#{self.is_new? ? "NEW ADVERTISER" : ""} #{aarp.page_name} (#{aarp.disclaimer}) spent #{self.spend_amount.to_s.reverse.scan(/\d{3}|.+/).join(",").reverse} in the last #{self.duration_days} days".strip
	end

end
