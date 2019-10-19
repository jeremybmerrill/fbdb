class CreateAdArchiveReportPages < ActiveRecord::Migration[6.0]
  def change
    create_table :ad_archive_report_pages do |t|
      t.bigint :page_id
      t.string :page_name
      t.string :disclaimer
      t.integer :amount_spent
      t.integer :ads_count
      t.integer :ad_archive_report_id

      t.timestamps
    end
  end
end
