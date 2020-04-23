require 'csv'

namespace :core_advertisers do 
  task refresh: :environment do 
    CSV.open("core_advertisers_20200422.csv").each do |row|
      if row[3] == "TRUE"
        wpage =       WritablePage.find_or_create_by(page_id: row[0])
        wpage.core = true
        wpage.save
      end
    end
  end
end
