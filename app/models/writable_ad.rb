
require 'aws-sdk-s3'

class WritableAd < ApplicationRecord
	belongs_to :ad, primary_key: :archive_id, foreign_key: :archive_id, optional: true
  belongs_to :ad_text, primary_key: :text_hash, foreign_key: :text_hash, optional: true
  belongs_to :fbpac_ad, primary_key: :id, foreign_key: :ad_id, optional: true
#  belongs_to :collector_ad
  belongs_to :page, primary_key: :page_id, foreign_key: :page_id, optional: true


  # for screenshots derived from Laura's DB.
  BUCKET_NAME = "qz-aistudio-fbpac-ads"
  def gcs_url
    ENV["GCS_URL"] + archive_id.to_s + ".png"
  end
  def generate_s3_url
    "s3:///#{BUCKET_NAME}/#{s3_path}"
  end
  def s3_path
    "screenshots/#{archive_id}.png"
  end

  def http_s3_url
    "https://qz-aistudio-fbpac-ads.s3.us-east-2.amazonaws.com/#{s3_path}"
  end

  def copy_screenshot_to_s3!
    return if s3_url
    s3 = Aws::S3::Resource.new(region:'us-east-2')
    begin 
      img_data = RestClient.get(gcs_url)
    rescue
      return
    end
    self.s3_url = generate_s3_url
    obj = s3.bucket(BUCKET_NAME).object(s3_path)
    obj.put(body: img_data.body, acl: "public-read")
    self.save
  end


end
