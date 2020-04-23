class AddSwingStateAdToWritableAds < ActiveRecord::Migration[6.0]
  def change
    add_column :writable_ads, :swing_state_ad, :boolean
  end
end
