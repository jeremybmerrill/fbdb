class AddPageIdIndexToWritableAds < ActiveRecord::Migration[6.0]
  def change
    add_index :writable_ads, :page_id
  end
end
