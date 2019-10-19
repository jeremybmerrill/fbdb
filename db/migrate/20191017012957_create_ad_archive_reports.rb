class CreateAdArchiveReports < ActiveRecord::Migration[6.0]
  def change
    create_table :ad_archive_reports do |t|
      t.datetime :scrape_date
      t.text :s3_url
      t.text :kind
      t.boolean :loaded, default: false

      t.timestamps
    end
  end
end
