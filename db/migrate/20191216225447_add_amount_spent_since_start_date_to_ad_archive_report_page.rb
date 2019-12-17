class AddAmountSpentSinceStartDateToAdArchiveReportPage < ActiveRecord::Migration[6.0]
  def change
    add_column :ad_archive_report_pages, :amount_spent_since_start_date, :integer
  end
end
