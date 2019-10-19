class AdArchiveReportPage < ApplicationRecord
	belongs_to :page, foreign_key: :page_id, primary_key: :page_id, optional: true
	belongs_to :writable_page, foreign_key: :page_id, primary_key: :page_id, optional: true
	belongs_to :ad_archive_report
    default_scope { order(:ad_archive_report_id) } 
end
