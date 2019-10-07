class CreateAdTopics < ActiveRecord::Migration[6.0]
  def change
    create_table :ad_topics do |t|
      t.bigint :archive_id
      t.integer :topic_id
      t.float :proportion

      t.timestamps
    end
  end
end
