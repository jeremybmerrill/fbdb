class AddUnaccentToPostgres < ActiveRecord::Migration[6.0]
  def up
    execute "create extension if not exists unaccent;"
  end
  def down

  end
end
