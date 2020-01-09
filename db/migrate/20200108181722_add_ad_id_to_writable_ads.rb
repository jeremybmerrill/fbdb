class AddAdIdToWritableAds < ActiveRecord::Migration[6.0]
  def change
    add_column :writable_ads, :ad_id, :text
  end
end
