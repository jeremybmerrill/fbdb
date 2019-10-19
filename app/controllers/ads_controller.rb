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

		query = Elasticsearch::DSL::Search.search do
		  query do
		  	multi_match do 
		      query search if search
		      fields [:text, :payer_name, :page_name]
		  	end
		    # TODO: targeting, if we end up getting it.
		    # TODO: filter by  states seen, impressions minimums/maximums, topics
		  end
		end
		@ads = Ad.search query
		respond_to do |format|
			format.html 
			format.json { render json: @ads.as_json(include: :fbpac_ad) }
		end
	end
end
