require 'elasticsearch/dsl'


class AdsController < ApplicationController

    def show
        if params[:archive_id]
            @ad = Ad.find_by(archive_id: params[:archive_id]) 
        elsif params[:ad_id]
            @ad = Ad.find(ad_id: params[:ad_id])
        end


        @fbpac_ad = @ad.fbpac_ad
        @writable_ad = @ad.writable_ad

        respond_to do |format|
          format.html
          format.json { render json: {
            ad: @ad.as_json(include: [:fbpac_ad, :writable_ad, :topics])
          } }
        end
    end

    # ed293d9358f9e3ed11b07433fd2e381687dac947 has both fbpac_ads and ads
    def show_by_text
        @fbpac_ads = FbpacAd.joins(:writable_ad).includes(:writable_ad).where({writable_ads: {text_hash: params[:text_hash]}})
        @ads  =       Ad.joins(:writable_ad).includes(:writable_ad).includes(:impressions).where({writable_ads: {text_hash: params[:text_hash]}})

        @text = @ads.first&.text || @fbpac_ads&.first&.message
        @fbpac_ads_count = @fbpac_ads.count
        @api_ads_count = @ads.count
        @min_spend = @ads.joins(:impressions).sum(:min_spend)
        @max_spend = @ads.joins(:impressions).sum(:max_spend)
        @min_impressions = @ads.joins(:impressions).sum(:min_impressions)
        @max_impressions = @ads.joins(:impressions).sum(:max_impressions)

        #TODO: distinct images/videos (needs ad library scrape, I think)

        respond_to do |format|
          format.html
          format.json { render json: {
            text: @text,
            fbpac_ads_count: @fbpac_ads_count,
            api_ads_count: @api_ads_count,
            min_spend: @min_spend,
            max_spend: @max_spend,
            min_impressions: @min_impressions,
            max_impressions: @max_impressions,
            ads: @ads.as_json(include: [:impressions, :writable_ad]) + @fbpac_ads.as_json(include: [:writable_ad]),
            } 
          }
        end
    end

    def overview
        @ads_count       = Ad.count
        @fbpac_ads_count = FbpacAd.count
        @big_spenders = BigSpender.preload(:writable_page).preload(:ad_archive_report_page).preload(:page)
        @top_advertisers = ActiveRecord::Base.connection.exec_query('SELECT ad_archive_report_pages.page_id, 
            ad_archive_report_pages.page_name, 
            sum(amount_spent_since_start_date)  sum_amount_spent
            FROM ad_archive_report_pages 
            WHERE ad_archive_report_pages.ad_archive_report_id = $1
            GROUP BY page_id, page_name 
            ORDER BY sum_amount_spent desc limit $2', nil, 
            [[nil, AdArchiveReport.where(kind: 'lifelong', loaded: true).order(:scrape_date).last.id], [nil, 20]]
            ).rows
        @top_disclaimers = ActiveRecord::Base.connection.exec_query('SELECT 
            payers.id,
            ad_archive_report_pages.disclaimer, 
            sum(amount_spent_since_start_date)  sum_amount_spent 
            FROM ad_archive_report_pages 
            JOIN payers
            ON disclaimer = name
            WHERE ad_archive_report_pages.ad_archive_report_id = $1 
            GROUP BY disclaimer, payers.id 
            ORDER BY sum_amount_spent desc limit $2', nil, 
            [[nil, AdArchiveReport.where(kind: 'lifelong', loaded: true).order(:scrape_date).last.id], [nil, 20]]
            ).rows
        respond_to do |format|
            format.html 
        end
    end

    def index
        # eventually the search method? 
        # this is the method for browinsg random recent ads
        @ads = Ad.includes(:writable_ad).paginate(page: params[:page], per_page: 30)

        respond_to do |format|
            format.html 
            format.json { render json: @ads.as_json(include: :writable_ad) }
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
        topic = params[:topic]
        no_payer = params[:no_payer]
        lang = params[:lang]

        query = Elasticsearch::DSL::Search.search do
          query do
            bool do
              must do
                multi_match do
                  query search
                    fields [
                            :text, :payer_name, :page_name, # Ad
                            :message, :advertiser, :paid_for_by # FbpacAd
                        ]
                end if search
              end if search
              filter do
                range :creation_date do  
                  gte publish_date 
                end 
                # targeting is included via FBPAC. But what do we do about searching ads that don't have an ATIAd counterpart??
                # TODO: targeting, if we end up getting it.
                # TODO: filter by  states seen, impressions minimums/maximums, topics

                # should this actually search AdTexts, which join to both Ad and FbpacAd?

              end if publish_date
              filter do
                terms topics: [topic]
              end if topic
              filter do
                term page_id: page_id.to_i 
              end if page_id
              filter do
                term lang: lang
              end if lang
              filter do
                term paid_for_by: FbpacAd::MISSING_STR  # will ONLY return FBPAC ads
              end if no_payer
            end
          end
          sort do 
            by :creation_date, 'desc'
          end
        end
        @mixed_ads = Elasticsearch::Model.search(query, [Ad, FbpacAd]).paginate(page: params[:page], per_page: 30).records(includes: :writable_ad)

        puts @mixed_ads.inspect

        respond_to do |format|
            format.html 
            format.json { 
                render json: @mixed_ads.as_json(include: :writable_ad)
             }
        end
    end
end
