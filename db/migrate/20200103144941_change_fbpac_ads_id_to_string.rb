class ChangeFbpacAdsIdToString < ActiveRecord::Migration[6.0]
  def up
    change_column :fbpac_ads, :id, :text
  end

  def down
    change_column :fbpac_ads, :id, :bigint
  end
end
