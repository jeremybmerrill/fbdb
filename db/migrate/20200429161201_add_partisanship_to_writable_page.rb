class AddPartisanshipToWritablePage < ActiveRecord::Migration[6.0]
  def change
    add_column :writable_pages, :partisanship, :string
  end
end
