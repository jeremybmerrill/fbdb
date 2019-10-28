class AddIndexToAdArchiveReportPages < ActiveRecord::Migration[6.0]
  def change
    add_index :ad_archive_report_pages, [:ad_archive_report_id, :page_id], name: "index_ad_archive_report_pages_on_ad_archive_report_id_page_id"
  end

end
