class AddUnaccentToPostgres < ActiveRecord::Migration[6.0]
  def change
    execute "create extension if not exists unaccent;"
  end
end
