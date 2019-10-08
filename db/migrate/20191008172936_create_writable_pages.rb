class CreateWritablePages < ActiveRecord::Migration[6.0]
  def change
    create_table :writable_pages do |t|
      t.bigint :page_id
      t.text :notes

      t.timestamps
    end
  end
end
