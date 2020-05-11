class AddAarIdPageIdDisclaimerIndexToAdArchiveReportPages < ActiveRecord::Migration[6.0]
  def change
    add_index :ad_archive_report_pages, [:ad_archive_report_id, :page_id, :disclaimer], name: "index_aarps_aar_id_page_id_discl"
  end
end
