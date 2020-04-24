require 'csv'

namespace :core_advertisers do 
  task refresh: :environment do 
    OTHERS = [706716899745696, 607626319739286, 1771156219840594] # team trump, women for trump, black voices for trump

    page_ids = CSV.open("core_advertisers_20200422.csv").select{ |row| row[3] == "TRUE" }.map{|row| row[0]} + OTHERS
    page_ids.each do |page_id|
      wpage =       WritablePage.find_or_create_by(page_id: page_id)
      wpage.core = true
      wpage.save
    end
  end
end
