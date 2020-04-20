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

    # this should redirect to the show_by_text
    #   so that from an FB ad ID, we can get to the show_by_text.
    def show
        if params[:archive_id]
            @some_kind_of_ad = Ad.find_by(archive_id: params[:archive_id]) 
        elsif params[:ad_id]
            @some_kind_of_ad = FbpacAd.find_by(id: params[:ad_id])
        end

        raise ActiveRecord::RecordNotFound if @some_kind_of_ad.nil?

        ad_text = @some_kind_of_ad.ad_text

        respond_to do |format|
          format.html {
            redirect_to "https://dashboard.qz.ai/ad/#{ad_text.text_hash}"
          }
          format.json { render json: {
            ad_text: ad_text
          } }
        end
    end

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


    def search_with_union
        # this takes longer. not a success.
        search = params[:search]
        lang = params[:lang] || "en-US" # TODO.
        page_ids = params[:page_id] ? JSON.parse(params[:page_id]) : []
        advertiser_names = params[:advertisers] ? JSON.parse(params[:advertisers])  : []
        publish_date = params[:publish_date] # e.g. "2019-01-01"
        topic_id = params[:topic_id] # TODO: this isn't supported yet by the frontend, it just sends a topic name
        topic_id = Topic.find_by(topic: params[:topic])&.id if !topic_id && params[:topic]
        no_payer = params[:no_payer]
        paid_for_by = params[:paid_for_by] # TODO support multiple? (should be same as page_ids)
        targeting = params[:targeting].nil? ? nil : JSON.parse(params[:targeting]) # [["MinAge", 59], ["Interest", "Sean Hannity"]]
        poliprob =  params[:poliprob] ? JSON.parse(params[:poliprob]) : [70, 100]
        new_page_ids = Page.where(page_name: [advertiser_names]).select("page_id").map(&:page_id)
        advertiser_names += Page.where(page_id: page_ids).select("page_name").map(&:page_name)
        page_ids += new_page_ids
        page_ids.uniq!
        advertiser_names.uniq!


        @fbpac_ads = AdText.joins(writable_ads: [:fbpac_ad]).where("fbpac_ads.lang = ?", lang) # ad_texts need lang (or country)
        @api_ads =   AdText.joins(:writable_ads)

        if search
            @fbpac_ads = @fbpac_ads.search_for(search)
            @api_ads   = @api_ads.search_for(search)
        end

        if page_ids.size + advertiser_names.size > 0  # can be either a number or an advertiser
            @fbpac_ads = @fbpac_ads.where("fbpac_ads.advertiser in (?)", advertiser_names)
            @api_ads = @api_ads.joins(writable_ads: [:ad]).where("ads.page_id in (?)", page_ids)
        end

        if publish_date
            @fbpac_ads = @fbpac_ads.where("fbpac_ads.created_at > ?",  publish_date)
            @api_ads = @api_ads.joins(writable_ads: [:ad]).where("ads.ad_creation_time > ?",  publish_date)
        end

        if poliprob.size != 2
            raise ArgumentError, "poliprob needs to be a JSON array of two numbers"
        end

        # POLITICAL PROBABILITY BIT
        # I'm not sure how this acts, or how it should act, with real FBAPI data, so I'm going to have to come back to it.
        @fbpac_ads = @fbpac_ads.where("fbpac_ads.political_probability >= ? and fbpac_ads.political_probability <= ?", poliprob[0] / 100.0, poliprob[1] / 100.0)

        if paid_for_by
            @fbpac_ads = @fbpac_ads.where("fbpac_ads.paid_for_by ilike",  paid_for_by.downcase)
            @api_ads = @api_ads.joins(writable_ads: [:ad]).where("ads.funding_entity ilike ?",  paid_for_by.downcase)
        end

        if topic_id
            puts "topic_id: #{topic_id}"
            @fbpac_ads = @fbpac_ads.joins(:ad_topics).where("ad_topics.topic_id": topic_id)
            @api_ads = @api_ads.joins(:ad_topics).where("ad_topics.topic_id": topic_id)
        end

        if no_payer # this exclude all Ad instances (since this query only makes sense when dealing with Fbpac_ads)
            @fbpac_ads = @fbpac_ads.where("fbpac_ads.paid_for_by is null")
            @api_ads = Ad.none
        end

        if targeting # this exclude all Ad instances (since this query only makes sense when dealing with Fbpac_ads)
                     # TODO: adapt for a way to combine teh params states, ages.
                     # needs to be transformed from [["MinAge", 59], ["Interest", "Sean Hannity"]] into
            @api_ads = Ad.none
            @fbpac_ads = @fbpac_ads.where("fbpac_ads.targets @> ?",  JSON.dump(targeting.map{|a, b| b ? {target: a.to_s, segment: b.to_s} : {target: a.to_s} }))
        end

        # TODO: sorting by the ad_text sort date is a bad idea, but I guess it's what we'll have to do.
        @ads = AdText.union(@api_ads.select("ad_texts.*, ad_texts.created_at as sort_key"), @fbpac_ads.select("ad_texts.*, fbpac_ads.created_at as sort_key")).includes(writable_ads: [:fbpac_ad, :ad], topics: {})

        @ads = @ads.order(Arel.sql("sort_key desc"))
        # it's better to sort by date, always (rather than relevance.)
        # if we search for a term, we're often looking for ads that contain the term
        # not for the "most relevant" ones. (if we use pg_search_rank, often older ads that use the term a lot (or are very short) get sorted to the top, which is not a good outcome)
        # here's how to do it we want to.

        # N.B. this is not distinct because SQL complains about 
        # having the ordering (on date) on something that's been discarded for the ordering.
        # the join is funny because each text_hash can join to multiple writable_ads (one for fbpac_ad and one for regular ad)
        @ads = @ads.paginate(page: params[:page], per_page: PAGE_SIZE, total_entries: PAGE_SIZE * 20) #.includes(writable_ads: [:fbpac_ad, :ad])
        # count queries on this join are hella expensive

        respond_to do |format|
            format.html 
            format.json { 
                render json: {
                    # because counts are very expensive, we are faking pagination and display one additional page if there's exactly PAGE_SIZE items returned by the current page
                    n_pages: @ads.to_a.size == PAGE_SIZE ? ([params[:page].to_i + 1, 2].max) : (params[:page] || 1),
                    page: params[:page] || 1,
                    ads: @ads.as_json(include: {writable_ads: {include: [:fbpac_ad, :ad]}}),
                }
             }
        end
    end


    def left_outer_join_search_without_ads
        search = params[:search]
        lang = params[:lang] || "en-US" # TODO.
        page_ids = params[:page_id] ? JSON.parse(params[:page_id]) : []
        advertiser_names = params[:advertisers] ? JSON.parse(params[:advertisers])  : []
        publish_date = params[:publish_date] # e.g. "2019-01-01"
        topic_id = params[:topic_id] # TODO: this isn't supported yet by the frontend, it just sends a topic name
        topic_id = Topic.find_by(topic: params[:topic])&.id if !topic_id && params[:topic]
        no_payer = params[:no_payer]
        paid_for_by = params[:paid_for_by] # TODO support multiple? (should be same as page_ids)
        targeting = params[:targeting].nil? ? nil : JSON.parse(params[:targeting]) # [["MinAge", 59], ["Interest", "Sean Hannity"]]
        poliprob =  params[:poliprob] ? JSON.parse(params[:poliprob]) : [70, 100]
        new_page_ids = Page.where(page_name: [advertiser_names]).select("page_id").map(&:page_id)
        advertiser_names += Page.where(page_id: page_ids).select("page_name").map(&:page_name)
        page_ids += new_page_ids
        page_ids.uniq!
        advertiser_names.uniq!

        # APR17: .includes(writable_ads: [:fbpac_ad, :ad], topics: {}) was here
        @ads = AdText.left_outer_joins(writable_ads: [:fbpac_ad]).where("fbpac_ads.lang = ? or writable_ads.archive_id is not null", lang) # ad_texts need lang (or country)
        
        @ads = @ads.order("ad_texts.first_seen desc")

        # it's better to sort by date, always (rather than relevance.)
        # if we search for a term, we're often looking for ads that contain the term
        # not for the "most relevant" ones. (if we use pg_search_rank, often older ads that use the term a lot (or are very short) get sorted to the top, which is not a good outcome)
        # here's how to do it we want to.
        if search
            @ads = @ads.search_for(search) # TODO maybe this should be by date too.
        end


        if page_ids.size + advertiser_names.size > 0  # can be either a number or an advertiser
            @ads = @ads.left_outer_joins(writable_ads: [:fbpac_ad, :ad]).where("fbpac_ads.advertiser in (?) or ads.page_id in (?)", advertiser_names, page_ids)
        end

        if publish_date
            @ads = @ads.where("writable_ads.ad_creation_time > ?",  publish_date, publish_date)
        end

        if poliprob.size != 2
            raise ArgumentError, "poliprob needs to be a JSON array of two numbers"
        end
        condition = "(fbpac_ads.political_probability >= ? and fbpac_ads.political_probability <= ?) or writable_ads.archive_id is not null"
        @ads = @ads.where(condition, poliprob[0] / 100.0, poliprob[1] / 100.0)

        # NO WAY TO AVOID A JOIN WITH ads THAT ISN"T INDEXED
        if paid_for_by
            @ads = @ads.left_outer_joins(writable_ads: [:fbpac_ad, :ad]).where("fbpac_ads.paid_for_by ilike ? or ads.funding_entity ilike ?",  paid_for_by.downcase, paid_for_by.downcase)
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
        @ads = @ads.includes(writable_ads: [:fbpac_ad, :ad], topics: {}).paginate(page: params[:page], per_page: PAGE_SIZE, total_entries: PAGE_SIZE * 20) #.includes(writable_ads: [:fbpac_ad, :ad])
        # count queries on this join are hella expensive

        # a possibility here (also involving ad_text's AdText.jsonify)
        # would be to do the "includes" myself to avoid looking up ALL the variants for an ad_text.
        # it's kind of complicated re-doing all of Rails's work in the "includes" method.
        # @ads = @ads.includes(:writable_ads)
        # fbpac_ads = Hash[*FbpacAd.find(@ads.map{|ad_text| ad_text.writable_ads.first(2).map(&:ad_id)}.flatten.compact).map{|ad| [ad.id, ad]}.flatten]
        # api_ads = Hash[*Ad.find(@ads.map{|ad_text| ad_text.writable_ads.first(2).map(&:archive_id)}.flatten.compact).map{|ad| [ad.archive_id, ad]}.flatten]
        # @ads.map{|ad_text| AdText.jsonify(ad_text, fbpac_ads, api_ads)}


        respond_to do |format|
            format.html 
            format.json { 
                render json: {
                    # because counts are very expensive, we are faking pagination and display one additional page if there's exactly PAGE_SIZE items returned by the current page
                    n_pages: @ads.to_a.size == PAGE_SIZE ? ([params[:page].to_i + 1, 2].max) : (params[:page] || 1),
                    page: params[:page] || 1,
                    ads: @ads.as_json(include: {writable_ads: {include: [:fbpac_ad, :ad]}}),
                }
             }
        end
    end


    def jeremys_double_method_search
        search = params[:search]
        lang = params[:lang] || "en-US" # TODO.
        page_ids = params[:page_id] ? JSON.parse(params[:page_id]) : []
        advertiser_names = params[:advertisers] ? JSON.parse(params[:advertisers])  : []
        publish_date = params[:publish_date] # e.g. "2019-01-01"
        topic_id = params[:topic_id] # TODO: this isn't supported yet by the frontend, it just sends a topic name
        topic_id = Topic.find_by(topic: params[:topic])&.id if !topic_id && params[:topic]
        no_payer = params[:no_payer]
        paid_for_by = params[:paid_for_by] # TODO support multiple? (should be same as page_ids)
        targeting = params[:targeting].nil? ? nil : JSON.parse(params[:targeting]) # [["MinAge", 59], ["Interest", "Sean Hannity"]]
        poliprob =  params[:poliprob] ? JSON.parse(params[:poliprob]) : [70, 100]

        # if you specify an advertiser by name (as the app does as of 4/17/20), e.g. /ads/search.json?advertisers=[%22Joe%20Biden%22]&poliprob=[70,100]
        # then we have to find the page_id that matches in order to get the ads for that advertiser from the HL FBAPI DB.
        new_page_ids = Page.where(page_name: [advertiser_names]).select("page_id").map(&:page_id)
        advertiser_names += Page.where(page_id: page_ids).select("page_name").map(&:page_name)
        page_ids += new_page_ids
        page_ids.uniq!
        advertiser_names.uniq!

        if params[:publish_date] || params[:paid_for_by]
            # if the search requires joining to the `ads` table to use columns there (that aren't on ad_texts or writable_ads)
            # then we have to do the search via the UNION method.
            # e.g. ?advertisers=[%22Joe%20Biden%22]&poliprob=[70,100]
            @fbpac_ads = AdText.joins(writable_ads: [:fbpac_ad]).where("fbpac_ads.lang = ?", lang) # ad_texts need lang (or country)
            @api_ads =   AdText.joins(:writable_ads)

            if search
                @fbpac_ads = @fbpac_ads.search_for(search)
                @api_ads   = @api_ads.search_for(search)
            end

            if page_ids.size + advertiser_names.size > 0  # can be either a number or an advertiser
                @fbpac_ads = @fbpac_ads.where("fbpac_ads.advertiser in (?)", advertiser_names)
                @api_ads = @api_ads.joins(writable_ads: [:ad]).where("ads.page_id in (?)", page_ids)
            end

            if publish_date
                @fbpac_ads = @fbpac_ads.where("fbpac_ads.created_at > ?",  publish_date)
                @api_ads = @api_ads.joins(writable_ads: [:ad]).where("ads.ad_creation_time > ?",  publish_date)
            end

            if poliprob.size != 2
                raise ArgumentError, "poliprob needs to be a JSON array of two numbers"
            end

            # POLITICAL PROBABILITY BIT
            # I'm not sure how this acts, or how it should act, with real FBAPI data, so I'm going to have to come back to it.
            @fbpac_ads = @fbpac_ads.where("fbpac_ads.political_probability >= ? and fbpac_ads.political_probability <= ?", poliprob[0] / 100.0, poliprob[1] / 100.0)

            if paid_for_by
                @fbpac_ads = @fbpac_ads.where("fbpac_ads.paid_for_by ilike",  paid_for_by.downcase)
                @api_ads = @api_ads.joins(writable_ads: [:ad]).where("ads.funding_entity ilike ?",  paid_for_by.downcase)
            end

            if topic_id
                puts "topic_id: #{topic_id}"
                @fbpac_ads = @fbpac_ads.joins(:ad_topics).where("ad_topics.topic_id": topic_id)
                @api_ads = @api_ads.joins(:ad_topics).where("ad_topics.topic_id": topic_id)
            end

            if no_payer # this exclude all Ad instances (since this query only makes sense when dealing with Fbpac_ads)
                @fbpac_ads = @fbpac_ads.where("fbpac_ads.paid_for_by is null")
                @api_ads = Ad.none
            end

            if targeting # this exclude all Ad instances (since this query only makes sense when dealing with Fbpac_ads)
                         # TODO: adapt for a way to combine teh params states, ages.
                         # needs to be transformed from [["MinAge", 59], ["Interest", "Sean Hannity"]] into
                @api_ads = Ad.none
                @fbpac_ads = @fbpac_ads.where("fbpac_ads.targets @> ?",  JSON.dump(targeting.map{|a, b| b ? {target: a.to_s, segment: b.to_s} : {target: a.to_s} }))
            end

            # TODO: sorting by the ad_text sort date is a bad idea, but I guess it's what we'll have to do.
            @ads = AdText.union(@api_ads, @fbpac_ads).includes(writable_ads: [:fbpac_ad, :ad], topics: {})

            @ads = @ads.order(Arel.sql("last_seen desc"))
            # it's better to sort by date, always (rather than relevance.)
            # if we search for a term, we're often looking for ads that contain the term
            # not for the "most relevant" ones. (if we use pg_search_rank, often older ads that use the term a lot (or are very short) get sorted to the top, which is not a good outcome)
            # here's how to do it we want to.

            # N.B. this is not distinct because SQL complains about 
            # having the ordering (on date) on something that's been discarded for the ordering.
            # the join is funny because each text_hash can join to multiple writable_ads (one for fbpac_ad and one for regular ad)
            @ads = @ads.paginate(page: params[:page], per_page: PAGE_SIZE, total_entries: PAGE_SIZE * 20) #.includes(writable_ads: [:fbpac_ad, :ad])
            # count queries on this join are hella expensive

        else # if it DOESN'T require those columns (e.g. keyword search), it's quicker to do it via LEFT OUTER JOINS
            # e.g. ?search="trump"
            # APR17: .includes(writable_ads: [:fbpac_ad, :ad], topics: {}) was here
            @ads = AdText.left_outer_joins(writable_ads: [:fbpac_ad]).where("fbpac_ads.lang = ? or writable_ads.archive_id is not null", lang) # ad_texts need lang (or country)
            
            @ads = @ads.order("writable_ads.created_at desc")

            # it's better to sort by date, always (rather than relevance.)
            # if we search for a term, we're often looking for ads that contain the term
            # not for the "most relevant" ones. (if we use pg_search_rank, often older ads that use the term a lot (or are very short) get sorted to the top, which is not a good outcome)
            # here's how to do it we want to.
            if search
                @ads = @ads.search_for(search) # TODO maybe this should be by date too.
            end


            if page_ids.size + advertiser_names.size > 0  # can be either a number or an advertiser
                @ads = @ads.where("fbpac_ads.advertiser in (?) or ad_texts.page_id in (?)", advertiser_names, page_ids)
            end

            if publish_date
                @ads = @ads.where("writable_ads.ad_creation_time > ?",  publish_date, publish_date)
            end

            if poliprob.size != 2
                raise ArgumentError, "poliprob needs to be a JSON array of two numbers"
            end
            condition = "(fbpac_ads.political_probability >= ? and fbpac_ads.political_probability <= ?) or writable_ads.archive_id is not null"
            @ads = @ads.where(condition, poliprob[0] / 100.0, poliprob[1] / 100.0)

            # NO WAY TO AVOID A JOIN WITH ads THAT ISN"T INDEXED
            if paid_for_by
                @ads = @ads.left_outer_joins(writable_ads: [:fbpac_ad, :ad]).where("fbpac_ads.paid_for_by ilike ? or ads.funding_entity ilike ?",  paid_for_by.downcase, paid_for_by.downcase)
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
            @ads = @ads.includes(writable_ads: [:fbpac_ad, :ad], topics: {}).paginate(page: params[:page], per_page: PAGE_SIZE, total_entries: PAGE_SIZE * 20) #.includes(writable_ads: [:fbpac_ad, :ad])
            # count queries on this join are hella expensive


        end

        respond_to do |format|
            format.html 
            format.json { 
                render json: {
                    # because counts are very expensive, we are faking pagination and display one additional page if there's exactly PAGE_SIZE items returned by the current page
                    n_pages: @ads.to_a.size == PAGE_SIZE ? ([params[:page].to_i + 1, 2].max) : (params[:page] || 1),
                    page: params[:page] || 1,
                    ads: @ads.as_json(include: {writable_ads: {include: [:fbpac_ad, :ad]}}),
                }
             }
        end
    end


    def search
        search = params[:search]
        lang = params[:lang] || "en-US" # TODO.
        page_ids = params[:page_id] ? JSON.parse(params[:page_id]) : []
        advertiser_names = params[:advertisers] ? JSON.parse(params[:advertisers])  : []
        publish_date = params[:publish_date] # e.g. "2019-01-01"
        topic_id = params[:topic_id] # TODO: this isn't supported yet by the frontend, it just sends a topic name
        topic_id = Topic.find_by(topic: params[:topic])&.id if !topic_id && params[:topic]
        no_payer = params[:no_payer]
        paid_for_by = params[:paid_for_by] # TODO support multiple? (should be same as page_ids)
        targeting = params[:targeting].nil? ? nil : JSON.parse(params[:targeting]) # [["MinAge", 59], ["Interest", "Sean Hannity"]]
        poliprob =  params[:poliprob] ? JSON.parse(params[:poliprob]) : [70, 100]
        new_page_ids = Page.where(page_name: [advertiser_names]).select("page_id").map(&:page_id)
        advertiser_names += Page.where(page_id: page_ids).select("page_name").map(&:page_name)
        page_ids += new_page_ids
        page_ids.uniq!
        advertiser_names.uniq!


        @ads = AdText.left_outer_joins(writable_ads: [:fbpac_ad, :ad]).includes(writable_ads: [:fbpac_ad, :ad], topics: {}).where("fbpac_ads.lang = ? or ads.archive_id is not null", lang) # ad_texts need lang (or country)
        
        @ads = @ads.order(Arel.sql("coalesce(fbpac_ads.created_at, ads.ad_creation_time) desc"))
        # it's better to sort by date, always (rather than relevance.)
        # if we search for a term, we're often looking for ads that contain the term
        # not for the "most relevant" ones. (if we use pg_search_rank, often older ads that use the term a lot (or are very short) get sorted to the top, which is not a good outcome)
        # here's how to do it we want to.
        if search
            @ads = @ads.search_for(search) # TODO maybe this should be by date too.
        end


        if page_ids.size + advertiser_names.size > 0  # can be either a number or an advertiser
            @ads = @ads.where("fbpac_ads.advertiser in (?) or ads.page_id in (?)", advertiser_names, page_ids)
        end

        if publish_date
            @ads = @ads.where("fbpac_ads.created_at > ? or ads.ad_creation_time > ?",  publish_date, publish_date)
        end

        if poliprob.size != 2
            raise ArgumentError, "poliprob needs to be a JSON array of two numbers"
        end
        condition = "(fbpac_ads.political_probability >= ? and fbpac_ads.political_probability <= ?) or ads.archive_id is not null"
        # I'm not sure how this acts, or how it should act, with real FBAPI data, so I'm going to have to come back to it.
        @ads = @ads.where(condition, poliprob[0] / 100.0, poliprob[1] / 100.0)

        if paid_for_by
            @ads = @ads.where("fbpac_ads.paid_for_by ilike ? or ads.funding_entity ilike ?",  paid_for_by.downcase, paid_for_by.downcase)
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
        @ads = @ads.paginate(page: params[:page], per_page: PAGE_SIZE, total_entries: PAGE_SIZE * 20) #.includes(writable_ads: [:fbpac_ad, :ad])
        # count queries on this join are hella expensive

        respond_to do |format|
            format.html 
            format.json { 
                render json: {
                    # because counts are very expensive, we are faking pagination and display one additional page if there's exactly PAGE_SIZE items returned by the current page
                    n_pages: @ads.to_a.size == PAGE_SIZE ? ([params[:page].to_i + 1, 2].max) : (params[:page] || 1),
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

    TIME_UNITS = ["day", "week", "month", "year", "electioncycle"]
    PIVOT_SELECTS = {
        "targets" => "jsonb_array_elements(targets)->>'target'",
        "segments" => "array[jsonb_array_elements(targets)->>'target', jsonb_array_elements(targets)->>'segment']",
        "paid_for_by" => "paid_for_by",
        "advertiser" => "advertiser"
    }
    def pivot
        # time_unit: ["day", "week", "month", "year", "electioncycle"]
        # time_count: integers
        # kind: "targets" "segments" "paid_for_by" "advertiser"
        # first_seen: true/false
        lang = params[:lang] || "en-US"
        @time_unit = params[:time_unit]
        raise if @time_unit && !TIME_UNITS.include?(@time_unit)
        @time_count = params[:time_count].to_i
        if @time_unit == "electioncycle"
            time_string = "'2019-11-17'" # after the Louisiana special
        else
            time_string = "NOW() - interval '#{@time_count} #{@time_unit}'"
        end

        @kind_of_thing = params[:kind]
        @first_seen = params[:first_seen] || false

        ads = FbpacAd.where("political_probability > 0.70 and suppressed = false").where(lang: lang).where("targets is not null")
        if (@time_count && @time_unit)
            if @first_seen
                ads = ads.having("min(created_at) > #{time_string}")
            else
                ads = ads.where("created_at > #{time_string}")
            end
        end
        @pivot = ads.unscope(:order).group(PIVOT_SELECTS[@kind_of_thing]).order("count_all desc").count
        respond_to do |format|
            format.html
            format.json {
                render json: @pivot #Hash[*pivot.map{|k, v| {paid_for_by: k, count: v} }]
            }
        end

    end

end
