class AddPageIdToWritableAds < ActiveRecord::Migration[6.0]
  def change
    add_column :writable_ads, :page_id, :bigint
  end
end
