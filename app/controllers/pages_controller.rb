class PagesController < ApplicationController


	def show

		@page = Page.find_by(page_id: params[:id])

		# count of ads
		@count_ads = @page.ads.size

		# sum of min impressions for all ads

		# count of distinct advertisers

		# sum of spend for all advertisers

		# breakdown of topics for all ads.

		# TODO: count of ads with a CollectorAd
		# TODO: targetings used

		# TODO: domain names linked to in ads (TODO: has to come from FBPAC or AdLibrary collector)

		# TODO: needs WritablePage for notes.

		respond_to do |format|
		  format.html
		  format.json { render json: {
		  	page: @page.page_name,
		    # notes: @page.notes,

		    ads: @count_ads,
		    # advertisers: @advertisers,

		    # min_impressions: @min_impressions,
		    # min_spend: @min_spend,
		    # topics: @topics

		  } }
		end

	end

	def index
		# lists all known payers
		@pages = Page.paginate(page: params[:page], per_page: 30)


		respond_to do |format|
			format.html 
			format.json { render json: @pages }
		end
	end

end
