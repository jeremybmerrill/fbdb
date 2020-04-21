class AddPageIdToFbpacAds < ActiveRecord::Migration[6.0]
  def change
    add_column :fbpac_ads, :page_id, :bigint
  end
end
