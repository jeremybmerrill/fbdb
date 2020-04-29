require 'csv'

namespace :core_advertisers do 
  task refresh: :environment do 
    GOP_OTHERS = [706716899745696, 607626319739286, 1771156219840594, 612701059241880].map{|id| [id, nil, nil, nil, 'gop']} # team trump, women for trump, black voices for trump, latinos for trump

    page_ids = CSV.open("core_advertisers_20200422.csv").select{ |row| row[3] == "TRUE" } + GOP_OTHERS
    page_ids.each do |row|
      wpage =       WritablePage.find_or_create_by(page_id: row[0].to_s.gsub("'", ''))
      wpage.core = true
      wpage.partisanship = row[4] 
      wpage.save
    end

    noncore_page_ids = CSV.open("core_advertisers_20200422.csv").select{ |row| row[3] == "FALSE" }
    noncore_page_ids.each do |row|
      wpage =       WritablePage.find_or_create_by(page_id: row[0].to_s.gsub("'", ''))
      wpage.core = false
      wpage.partisanship = nil
      wpage.save
    end
  end
end
