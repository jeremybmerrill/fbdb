class AddAdTextsIndexFirstSeenDescTextHash < ActiveRecord::Migration[6.0]
  def change
    add_index :ad_texts, [:first_seen, :text_hash], order: {first_seen: :desc, text_hash: :asc}
  end
end
