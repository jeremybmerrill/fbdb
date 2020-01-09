class AddTextHashToWritableAds < ActiveRecord::Migration[6.0]
  def change
    add_column :writable_ads, :text_hash, :string
    add_index :writable_ads, :text_hash
  end
end
