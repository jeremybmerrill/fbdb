class CreatePayers < ActiveRecord::Migration[6.0]
  def change
    create_table :payers do |t|
      t.string :name
      t.text :notes

      t.timestamps
    end
  end
end
