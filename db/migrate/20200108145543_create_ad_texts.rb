class CreateAdTexts < ActiveRecord::Migration[6.0]
  def change
    create_table :ad_texts do |t|
      t.text :text
      t.string :text_hash
      t.text :vec

      t.timestamps
    end
  end
end
