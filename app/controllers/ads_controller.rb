require 'elasticsearch/dsl'


class AdsController < ApplicationController

    def show
        if params[:archive_id]
            @ad = Ad.find_by(archive_id: params[:archive_id]) 
        elsif params[:ad_id]
            @ad = Ad.find(ad_id: params[:ad_id])
        end


        @fbpac_ad = @ad.fbpac_ad


        respond_to do |format|
          format.html
          format.json { render json: {
            ad: @ad.as_json(include: :fbpac_ad)
          } }
        end
    end

    def overview
        @ads_count       = Ad.count
        @fbpac_ads_count = FbpacAd.count
        
        @top_advertisers = AdArchiveReportPage.order("amount_spent desc").first(20)
        @top_disclaimers = AdArchiveReportPage.unscope(:order).order("sum_amount_spent desc").group("disclaimer").sum(:amount_spent).first(20)
        respond_to do |format|
            format.html 
        end
    end

    def index
        # eventually the search method?
        @ads = Ad.includes(:fbpac_ad).paginate(page: params[:page], per_page: 30)

        respond_to do |format|
            format.html 
            format.json { render json: @ads.as_json(include: :fbpac_ad) }
        end
    end

    def search
        # keywordsearch: ad text
        # keywordsearch URL?
        # some sort of search UTM params
        # keywordsearch: targeting 
        # filter: disclaimer, advertiser
        # keywordsearch disclaimers?
        # time based filter

        
        search = params[:search]
        page_id = params[:page_id]
        publish_date = nil # "2019-01-01"

        puts page_id

        query = Elasticsearch::DSL::Search.search do
          query do
            bool do
              must do
                multi_match do
                  query search
                  fields [:text, :payer_name, :page_name]
                end 
              end if search
              filter do
                term page_id: page_id.to_i if page_id
                range :creation_date do  
                  gte publish_date 
                end if publish_date
                # TODO: targeting, if we end up getting it.
                # TODO: filter by  states seen, impressions minimums/maximums, topics
              end if [page_id, publish_date].any?{|a| a }
            end
          end
        end
        @ads = Ad.search query
        respond_to do |format|
            format.html 
            format.json { render json: @ads.as_json(include: :fbpac_ad) }
        end
    end
end
