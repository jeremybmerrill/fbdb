class CreateWritableAds < ActiveRecord::Migration[6.0]
  def change
    create_table :writable_ads do |t|
      t.string :partisanship
      t.string :purpose
      t.string :optimism
      t.string :attack
      t.bigint :archive_id

      t.timestamps
    end
  end
end
