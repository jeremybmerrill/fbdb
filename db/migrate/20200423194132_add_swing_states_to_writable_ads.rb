class AddSwingStatesToWritableAds < ActiveRecord::Migration[6.0]
  def change
    add_column :writable_ads, :states, :text, array: true, default: []
  end
end
