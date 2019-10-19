class PayersController < ApplicationController

	def show
		@payer = Payer.find(params[:id])

		# count of ads
		@count_ads = @payer.ads.size

		# sum of min impressions for all ads
		@min_impressions = @payer.min_impressions

		# distinct advertisers (i.e. pages)
		@advertisers = @payer.advertisers

		# sum of spend for all advertisers
		@min_spend = @payer.min_spend

		aarps = @payer.ad_archive_report_pages.where(ad_archive_report: AdArchiveReport.order(:scrape_date).last)
		@precise_spend = aarps.sum(:amount_spent)
		@report_count_ads = aarps.sum(:ads_count)

		# breakdown of topics for all ads.
		@topics = @payer.topic_breakdown

		# TODO: count of ads with a CollectorAd
		@fbpac_ads_cnt = @payer.ads.joins(:fbpac_ad).count

		# TODO: targetings used

		# TODO: domain names linked to in ads (TODO: has to come from FBPAC or AdLibrary collector)

		respond_to do |format|
		  format.html
		  format.json { render json: {
		  	payer: @payer.name,
		    notes: @payer.notes,

		    ads: @count_ads,
		    fbpac_ads: @fbpac_ads_cnt,
		    advertisers: @advertisers,

		    min_impressions: @min_impressions,
		    min_spend: @min_spend,
		    precise_spend: @precise_spend,
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

	def index
		# lists all known payers
		@payers = Payer.paginate(page: params[:page], per_page: 30)


		respond_to do |format|
			format.html 
			format.json { render json: @payers }
		end
	end


end
