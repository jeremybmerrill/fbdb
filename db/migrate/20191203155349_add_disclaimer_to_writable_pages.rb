class AddDisclaimerToWritablePages < ActiveRecord::Migration[6.0]
  def change
    add_column :writable_pages, :disclaimer, :string
  end
end
