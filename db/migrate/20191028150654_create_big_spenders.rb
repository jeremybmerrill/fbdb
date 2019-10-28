class CreateBigSpenders < ActiveRecord::Migration[6.0]
  def change
    create_table :big_spenders do |t|
      t.integer :ad_archive_report_id
      t.integer :previous_ad_archive_report_id
      t.integer :ad_archive_report_page_id
      t.bigint :page_id
      t.integer :spend_amount
      t.integer :duration_days
      t.boolean :is_new

      t.timestamps
    end
  end
end
