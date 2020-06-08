class AddFbpacAdsIndex < ActiveRecord::Migration[6.0]
  def change
  	add_index :fbpac_ads, :id
  end
end
