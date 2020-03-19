require 'elasticsearch/dsl'

module Elasticsearch
  module DSL
    module Search
      module Filters
        class Nested
          def query(*args, &block)
            @query = block ? Elasticsearch::DSL::Search::Query.new(*args, &block) : args.first
            self
          end
          def to_hash
            hash = super
            if @filter
              _filter = @filter.respond_to?(:to_hash) ? @filter.to_hash : @filter
              hash[self.name].update(filter: _filter)
            end
            if @query
              _query = @query.respond_to?(:to_hash) ? @query.to_hash : @query
              hash[self.name].update(query: _query)
            end
            hash
          end
        end
      end
    end
  end
end

class AdsController < ApplicationController
    PAGE_SIZE = 30

    def show
        if params[:archive_id]
            @some_kind_of_ad = Ad.find_by(archive_id: params[:archive_id]) 
        elsif params[:ad_id]
            @some_kind_of_ad = FbpacAd.find(ad_id: params[:ad_id])
        end

        @writable_ad = @some_kind_of_ad.writable_ad

        respond_to do |format|
          format.html
          format.json { render json: {
            ad: @some_kind_of_ad.as_json(include: [:writable_ad, :topics])
          } }
        end
    end

    # ed293d9358f9e3ed11b07433fd2e381687dac947 has both fbpac_ads and ads
    def show_by_text
        @ad_text = AdText.left_outer_joins(writable_ads: [:fbpac_ad, :ad]).includes(writable_ads: [:fbpac_ad, :ad], topics: {}).find_by(text_hash: params[:text_hash])

        # @fbpac_ads = FbpacAd.joins(:writable_ad).includes(:writable_ad).where({writable_ads: {text_hash: params[:text_hash]}})
        # @ad_text  =       Ad.joins(:writable_ad).includes(:writable_ad).includes(:impressions).where({writable_ads: {text_hash: params[:text_hash]}})


        @text = @ad_text.ads&.first&.text || @ad_text.fbpac_ads&.first&.message
        @fbpac_ads_count = @ad_text.fbpac_ads.count
        @api_ads_count = @ad_text.ads.count
        @min_spend = @ad_text.impressions.sum(:min_spend)
        @max_spend = @ad_text.impressions.sum(:max_spend)
        @min_impressions = @ad_text.impressions.sum(:min_impressions)
        @max_impressions = @ad_text.impressions.sum(:max_impressions)

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
            ad: @ad_text.as_json(include: {writable_ads: {include: [:fbpac_ad, :ad]}}),
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
        @ads = Ad.includes(:writable_ad).paginate(page: params[:page], per_page: PAGE_SIZE)

        respond_to do |format|
            format.html 
            format.json { render json: {
                    total_ads: @ads.total_entries,
                    n_pages: @ads.total_pages,
                    page: params[:page] || 1,
                    ads: @ads.as_json(include: :writable_ad), 
                }
            }

        end
    end

    def search
        search = params[:search]
        lang = params[:lang] || "en-US" # TODO.
        page_ids = params[:page_id] ? [params[:page_id]] : []# TODO support multiple?
        advertiser_names = [] # TODO.
        publish_date = params[:publish_date] # e.g. "2019-01-01"
        topic_id = params[:topic_id] # TODO: this isn't supported yet by the frontend, it just sends a topic name
        topic_id = Topic.find_by(topic: params[:topic])&.id if !topic_id && params[:topic]
        no_payer = params[:no_payer]
        targeting = params[:targeting].nil? ? nil : JSON.parse(params[:targeting]) # [["MinAge", 59], ["Interest", "Sean Hannity"]]
        poliprob = JSON.parse(params[:poliprob]) if params[:poliprob]
        @ads = AdText.left_outer_joins(writable_ads: [:fbpac_ad, :ad]).includes(writable_ads: [:fbpac_ad, :ad], topics: {}).where("fbpac_ads.lang = ?", lang) # ad_texts need lang (or country)
        if params[:search]
            @ads = @ads.search_for(search).with_pg_search_rank # TODO maybe this should be by date too.
        else
            @ads = @ads.order(Arel.sql("coalesce(fbpac_ads.created_at, ads.creation_date) desc"))
        end

        if page_ids.size + advertiser_names.size > 0  # can be either a number or an advertiser
            @ads = @ads.where("fbpac_ads.advertiser in (?) or ads.page_id in (?)", advertiser_names, page_ids)
        end

        if publish_date
            @ads = @ads.where("fbpac_ads.created_at > ? or ads.creation_date > ?",  publish_date, publish_date)
        end
        if publish_date
            @ads = @ads.where("fbpac_ads.created_at > ? or ads.creation_date > ?",  publish_date, publish_date)
        end


        if poliprob
            if poliprob.size != 2
                raise ArgumentError, "poliprob needs to be a JSON array of two numbers"
            end
            condition = "(fbpac_ads.political_probability >= ? and fbpac_ads.political_probability <= ?) "
            # I'm not sure how this acts, or how it should act, with real FBAPI data, so I'm going to have to come back to it.
            # 
            #
            @ads = @ads.where(condition,  poliprob[0] / 100.0, poliprob[1] / 100.0)
        end


        if topic_id
            puts "topic_id: #{topic_id}"
            @ads = @ads.joins(:ad_topics).where("ad_topics.topic_id": topic_id)
        end

        if no_payer # this exclude all Ad instances (since this query only makes sense when dealing with Fbpac_ads)
            @ads = @ads.where("fbpac_ads.paid_for_by is null and ads.archive_id is null")
        end



        if targeting # this exclude all Ad instances (since this query only makes sense when dealing with Fbpac_ads)
                     # TODO: adapt for a way to combine teh params states, ages.
                     # needs to be transformed from [["MinAge", 59], ["Interest", "Sean Hannity"]] into

            @ads = @ads.where("fbpac_ads.targets @> ?",  JSON.dump(targeting.map{|a, b| b ? {target: a.to_s, segment: b.to_s} : {target: a.to_s} }))
        end

        # N.B. this is not distinct because SQL complains about 
        # having the ordering (on date) on something that's been discarded for the ordering.
        # the join is funny because each text_hash can join to multiple writable_ads (one for fbpac_ad and one for regular ad)
        @ads = @ads.paginate(page: params[:page], per_page: PAGE_SIZE) #.includes(writable_ads: [:fbpac_ad, :ad])

        respond_to do |format|
            format.html 
            format.json { 
                render json: {
                    total_ads: @ads.total_entries,
                    n_pages: @ads.total_pages,
                    page: params[:page] || 1,
                    ads: @ads.as_json(include: {writable_ads: {include: [:fbpac_ad, :ad]}}),
                }
             }
        end
    end

    def topics
        respond_to do |format|
            format.json {
                render json: {
                    topics: Topic.select(:id, :topic).map{|a| [a.topic, a.id]}
                }
            }
        end
    end

    def list_targets
        lang = params[:lang] || "en-US" # TODO.
        raise unless lang.match(/[a-z][a-z]-[A-Z][A-Z]/)
        counts = Ad.connection.execute("select jsonb_array_elements(targets)->>'target' target,jsonb_array_elements(targets)->>'segment' segment, count(*) from fbpac_ads WHERE lang = 'en-US' AND political_probability > 0.70 AND suppressed = false group by jsonb_array_elements(targets)->>'segment', jsonb_array_elements(targets)->>'target' order by count(*) desc;")
        grouped = counts.to_a.group_by{|row| row["target"]}.map{|targ, rows| [targ, rows.map{|a| a["segment"] }]}
        respond_to do |format|
            format.json {
                render json: {
                    grouped: grouped
                }
            }
        end
    end

    TIME_UNITS = ["day", "week", "month", "year"]
    PIVOT_SELECTS = {
        "targets" => "jsonb_array_elements(targets)->>'target'",
        "segments" => "array[jsonb_array_elements(targets)->>'target', jsonb_array_elements(targets)->>'segment']",
        "paid_for_by" => "paid_for_by",
        "advertiser" => "advertiser"
    }
    def pivot
        # time_unit: ["day", "week", "month", "year"]
        # time_count: integers
        # kind: "targets" "segments" "paid_for_by" "advertiser"
        # first_seen: true/false
        lang = params[:lang] || "en-US" # TODO.
        time_unit = params[:time_unit]
        raise if time_unit && !TIME_UNITS.include?(time_unit)
        time_count = params[:time_count].to_i
        time_string = "#{time_count} #{time_unit}"

        kind_of_thing = params[:kind]
        first_seen = params[:first_seen] || false

        ads = FbpacAd.where(lang: lang).where("targets is not null")
        if (time_count && time_unit)
            if first_seen
                ads = ads.having("min(created_at) > NOW() - interval '#{time_string}'")
            else
                ads = ads.where("created_at > NOW() - interval '#{time_string}'")
            end
        end
        pivot = ads.unscope(:order).group(PIVOT_SELECTS[kind_of_thing]).order("count_all desc").count
        respond_to do |format|
            format.json {
                render json: pivot #Hash[*pivot.map{|k, v| {paid_for_by: k, count: v} }]
            }
        end

    end

end
