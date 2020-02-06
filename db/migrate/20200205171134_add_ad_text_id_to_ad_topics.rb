class AddAdTextIdToAdTopics < ActiveRecord::Migration[6.0]
  def change
    add_column :ad_topics, :ad_text_id, :integer
  end
end
