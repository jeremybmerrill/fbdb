class AddSearchTextToAdTexts < ActiveRecord::Migration[6.0]
  def up
    add_column :ad_texts, :search_text, :text
    add_column :ad_texts, :tsv, :tsvector
    add_index :ad_texts,  :tsv, using: :gin

    execute <<-SQL
      CREATE TRIGGER tsvectorupdate BEFORE INSERT OR UPDATE
      ON ad_texts FOR EACH ROW EXECUTE PROCEDURE
      tsvector_update_trigger(
        tsv, 'pg_catalog.english', search_text
      );
    SQL

    now = Time.current.to_s(:db)
    update("UPDATE ad_texts SET updated_at = '#{now}'")
  end

  def down
    execute <<-SQL
      DROP TRIGGER tsvectorupdate
      ON ad_texts
    SQL

    remove_index :ad_texts, :tsv
    remove_column :ad_texts, :tsv
    remove_column :ad_texts, :search_text
  end


end
