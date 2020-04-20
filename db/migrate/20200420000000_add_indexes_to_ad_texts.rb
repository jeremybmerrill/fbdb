class AddIndexesToAdTexts < ActiveRecord::Migration[6.0]
  def change
    add_index :ad_texts, :page_id
    add_index :ad_texts, :advertiser
    add_index :ad_texts, :paid_for_by
    add_index :ad_texts, :first_seen
    add_index :ad_texts, :last_seen
    add_index :writable_ads, :archive_id
    add_index :writable_ads, :ad_id
  end
end
