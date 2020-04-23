class AddCoreToWritablePage < ActiveRecord::Migration[6.0]
  def change
    add_column :writable_pages, :core, :boolean, default: false
  end
end
