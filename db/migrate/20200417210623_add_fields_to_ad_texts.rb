class AddFieldsToAdTexts < ActiveRecord::Migration[6.0]
  def change
    add_column :ad_texts, :page_id, :bigint
    add_column :ad_texts, :advertiser, :text
    add_column :ad_texts, :paid_for_by, :text
    add_column :ad_texts, :first_seen, :datetime
    add_column :ad_texts, :last_seen, :datetime
  end
end
