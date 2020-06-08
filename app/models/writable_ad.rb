require 'aws-sdk-s3'

class WritableAd < ApplicationRecord
	belongs_to :ad, primary_key: :archive_id, foreign_key: :archive_id, optional: true
  belongs_to :ad_text, primary_key: :text_hash, foreign_key: :text_hash, optional: true
  belongs_to :fbpac_ad, primary_key: :id, foreign_key: :ad_id, optional: true
#  belongs_to :collector_ad
  belongs_to :page, primary_key: :page_id, foreign_key: :page_id, optional: true
  belongs_to :writable_page, primary_key: :page_id, foreign_key: :page_id, optional: true


  # for screenshots derived from Laura's DB.
  BUCKET_NAME = ENV["IMAGES_S3_BUCKET"]
  AWS_REGION = ENV["AWS_REGION"]
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
    "https://#{BUCKET_NAME}.s3.#{AWS_REGION}.amazonaws.com/#{s3_path}"
  end

  def copy_screenshot_to_s3!
    return if s3_url
    s3 = Aws::S3::Resource.new(region: AWS_REGION)
    obj = s3.bucket(BUCKET_NAME).object(s3_path)
    unless obj.exists?
      begin 
        img_data = RestClient.get(gcs_url)
      rescue
        return
      end
      obj.put(body: img_data.body, acl: "public-read")
    end
    self.s3_url = generate_s3_url
    self.save
  end


end
