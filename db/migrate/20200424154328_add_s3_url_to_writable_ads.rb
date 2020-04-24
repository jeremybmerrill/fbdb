class AddS3UrlToWritableAds < ActiveRecord::Migration[6.0]
  def change
    add_column :writable_ads, :s3_url, :text
  end
end
