class PayersController < ApplicationController

	def show
		@payer = Payer.find(params[:id])

		# count of ads
		@count_ads = @payer.ads.size

		# sum of min impressions for all ads
		@min_impressions = @payer.min_impressions

		# count of distinct advertisers
		@advertisers = @payer.advertisers
		# sum of spend for all advertisers
		@min_spend = @payer.min_spend

		# breakdown of topics for all ads.
		@topics = @payer.topic_breakdown

		# TODO: count of ads with a CollectorAd
		# TODO: targetings used

		# TODO: domain names linked to in ads (TODO: has to come from FBPAC or AdLibrary collector)

		respond_to do |format|
		  format.html
		  format.json { render json: {
		  	payer: @payer.name,
		    notes: @payer.notes,

		    ads: @count_ads,
		    advertisers: @advertisers,

		    min_impressions: @min_impressions,
		    min_spend: @min_spend,
		    topics: @topics

		  } }
		end

	end

	def index
		# lists all known payers
		@all = Payer.all
		respond_to do |format|
			format.html 
			format.json { render json: @all }
		end
	end
end
