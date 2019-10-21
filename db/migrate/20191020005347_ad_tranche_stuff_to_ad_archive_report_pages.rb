class AdTrancheStuffToAdArchiveReportPages < ActiveRecord::Migration[6.0]
  def change
  	change_table :ad_archive_report_pages do |t|
	  t.integer :ads_this_tranche
	  t.integer :spend_this_tranche
	end
  end
end
