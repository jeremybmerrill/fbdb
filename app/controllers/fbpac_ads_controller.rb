class FbpacAdsController < ApplicationController
    before_action :set_lang
    skip_before_action :authenticate_user!

    GENDERS_FB = ["men", "women"]
    MAX_PAGE = 50
    def persona
        @lang = "en-US"
        ads = FbpacAd.where(lang: @lang).where("political_probability > 0.7 and suppressed = false")

        ads = ads.unscope(:order)
        ads = ads.order("(CURRENT_DATE - created_at) / sqrt(greatest(targetedness, 1)) asc " )
        ads = ads.where("jsonb_array_length(targets) > 0")

        raise(ActionController::BadRequest.new, "you've gotta specify at least one bucket") unless [:age_bucket, :politics_bucket, :location_bucket, :gender].any?{|bucket| params.include?(bucket) }

        age_bucket_for_puts =
        if params[:age_bucket] && params[:age_bucket] != "--"
            age = [[params[:age_bucket].to_i, 65].min, 13].max

             ads = ads.where("not targets @> '[{\"target\": \"MinAge\"}]' OR " + Ad.send(:sanitize_sql_for_conditions, [
                (13..age).map{|_| "targets @> ?"}.join(" or ")
            ] + (13..age).map{|seg| "[{\"target\": \"MinAge\", \"segment\": \"#{seg}\"}]" } ))
                .where("not targets @> '[{\"target\": \"MaxAge\"}]' OR " + Ad.send(:sanitize_sql_for_conditions, [
                (age..65).map{|_| "targets @> ?"}.join(" or ")
            ] + (age..65).map{|seg| "[{\"target\": \"MaxAge\", \"segment\": \"#{seg}\"}]" } ))
            age_bucket_for_puts = "age: #{age}"
        else
            age_bucket_for_puts = "age: none"
        end
        if params[:location_bucket]
            # US ads,
            # state: location[0]
            # region: location[0]
            # state: location[0] && city: location[1]
            state, city = params[:location_bucket].split(",")
            if state != "any state"
                ads = ads.where("targets @> '[{\"target\": \"State\", \"segment\": \"#{state}\"}]' OR targets @> '[{\"target\": \"Region\", \"segment\": \"#{state}\"}]' OR targets @> '[{\"target\": \"Region\", \"segment\": \"United States\"}]'")

                ads = ads.where("(not targets @> '[{\"target\": \"City\"}]' OR targets @> '[{\"target\": \"City\", \"segment\": \"#{city}\"}]')") if city
            end
            loc_bucket_for_puts = "loc: #{state}, city: #{city}"
        else
            loc_bucket_for_puts = "loc: none"
        end

        politics = params[:politics_bucket] == "neither liberal nor conservative" ? "apolitical" : params[:politics_bucket]
        if politics && POLITICAL_BUCKETS.include?(politics)
            # targets @> '[{"target":"Segment","segment":"US politics (conservative)"}]'
            ads = ads.where(

                # segments
                Ad.send(:sanitize_sql_for_conditions, [
                    POLITICAL_BUCKETS[politics][:segment].map{|_| "targets @> ?"}.join(" or ")
                ] + POLITICAL_BUCKETS[politics][:segment].map{|seg| "[{\"target\": \"Segment\", \"segment\": \"#{seg}\"}]" } ) +

                # interests
                " OR " + Ad.send(:sanitize_sql_for_conditions, [
                    POLITICAL_BUCKETS[politics][:interest].map{|seg| "targets @> ?"}.join(" or ")
                ] + POLITICAL_BUCKETS[politics][:interest].map{|seg| "[{\"target\": \"Interest\", \"segment\": \"#{seg}\"}]" } ) +

                # non-politically-targeted ads
                # No interest and no segment list, like, etc.
                # Retargeting: recently near their business
                " OR (not targets @> '[{\"target\": \"Interest\"}]' AND not targets @> '[{\"target\": \"List\"}]' AND not targets @> '[{\"target\": \"Like\"}]' AND not targets @> '[{\"target\": \"Segment\"}]' AND not targets @> '[{\"target\": \"Website\"}]' AND not targets @> '[{\"target\": \"Agency\"}]'  AND not targets @> '[{\"target\": \"Engaged with Content\"}]' AND not targets @> '[{\"target\": \"Activity on the Facebook Family\"}]' AND not targets @> '[{\"target\": \"Retargeting\", \"segment\": \"people who may be similar to their customers\"}]' ) OR (targets @> '[{\"target\": \"Retargeting\", \"segment\": \"recently near their business\"}]')"
            )
            pol_bucket_for_puts = "pol: #{politics}"
        else
            pol_bucket_for_puts = "pol: none"
        end

        gender_regularizer = {
            "man" => "men",
            "male" => "men",
            "female" => "women",
            "woman" => "women",
            "a man" => "men",
            "a woman" => "women",
            "any gender" => nil
        }
        gender = gender_regularizer[params[:gender]]
        if gender && GENDERS_FB.include?(gender)
            other_gender = (GENDERS_FB - [gender]).first
            ads = ads.where("not targets @> ?", "[{\"target\": \"Gender\", \"segment\": \"#{other_gender}\"}]")
            gdr_bucket_for_puts = "gdr: #{gender}"
        else
            grd_bucket_for_puts = "gdr: none"
        end

        puts "#{age_bucket_for_puts}, #{loc_bucket_for_puts}, #{pol_bucket_for_puts}, #{gdr_bucket_for_puts}"

        # race, we're not doing;
        page_num = [params[:page].to_i || 0, MAX_PAGE].min
        ads_page = ads.page(page_num + 1)  # +1 here to mimic Rust behavior.
        resp = {}

        resp[:ads] = ads_page.map(&:as_propublica_json)
        resp[:total] = ads.count
        render json: resp
    end

    def show
        ad = FbpacAd.where("political_probability > 0.7 and suppressed = false").select(ADS_COLUMNS).find_by(lang: ["en-US", "de-DE"], id: params[:id])
        render json: ad.as_propublica_json(:except => [:suppressed])
    end


    HOMEPAGE_STATS_CACHE_PATH = lambda {|lang| "#{Rails.root}/tmp/homepage_stats-#{lang}.json"}
    def homepage_stats

        render file: HOMEPAGE_STATS_CACHE_PATH.call(@lang), content_type: "application/json", layout: false and return if File.exists?(HOMEPAGE_STATS_CACHE_PATH.call(@lang)) && (Time.now - File.mtime(HOMEPAGE_STATS_CACHE_PATH.call(@lang)) < 60 * 60 ) # just read it from disk if cached thingy exists and is less than 60 minutes old.
        stats = FbpacAd.calculate_homepage_stats(@lang)
        File.open(HOMEPAGE_STATS_CACHE_PATH.call(@lang), 'w'){|f| f.write(JSON.dump(stats))}
        STDERR.puts "wrote to disk since the cache doesn't exist"
        render json: stats
    end

    def write_homepage_stats
        raise 400 unless params[:secret] == "asdfasdf"

        File.open(HOMEPAGE_STATS_CACHE_PATH.call(@lang), 'w'){|f| f.write(JSON.dump(FbpacAd.calculate_homepage_stats(@lang)))}
        render text: "ok"
    end

    CANDIDATE_PARAMS = Set.new(["states", "districts", "parties", "joined"])
    ADS_COLUMNS = [:impressions, :paid_for_by, :targets, :html, :lang, :id, "fbpac_ads.created_at", :advertiser, :suppressed, :political_probability, :political, :not_political, :targeting, :title, :lower_page, :listbuilding_fundraising_proba]
    def index
        expires_in(1.hours, public: true, must_revalidate: true)

        ads = FbpacAd.where(lang: @lang).where("political_probability > 0.7 and suppressed = false").order("fbpac_ads.created_at desc")

        if params[:search]
            # to_englishtsvector("ads"."html") @@ to_englishtsquery($4)
            ads = ads.where(@lang[0..2] == "de" ? "to_germantsvector(html) @@ to_germantsquery(?)" : "to_englishtsvector(html) @@ to_englishtsquery(?)", params[:search])
        end

        if params[:targets]
            ads = ads.where("targets @> ?", params[:targets])
        end
        if params[:advertisers]
            ads = ads.where("advertiser in (?)", JSON.parse(params[:advertisers]))
        end

        page_num = [params[:page].to_i || 0, MAX_PAGE].min
        ads_page = ads.page((page_num.to_i || 0) + 1) # +1 here to mimic Rust behavior.

        resp = {}

        resp[:ads] = ads_page.select( *(ADS_COLUMNS)).map(&:as_propublica_json)
        resp[:targets] = ads.unscope(:order).where("targets is not null").group("jsonb_array_elements(targets)->>'target'").order("count_all desc").limit(20).count.map{|k, v| {target: k, count: v} }
        resp[:entities] = ads.unscope(:order).where("entities is not null").group("jsonb_array_elements(entities)->>'entity'").order("count_all desc").limit(20).count.map{|k, v| {entity: k, count: v} }
        resp[:advertisers] = ads.unscope(:order).where("advertiser is not null").group("advertiser").order("count_all desc").limit(20).count.map{|k, v| {advertiser: k, count: v} }
        resp[:total] = ads.count
        render json: resp
    end

    private

    def set_lang
        @lang = params[:lang] || "en-US" # || http_accept_language.user_preferred_languages.find{|lang| lang.match(/..-../)} || "en-US"
        if @lang == "*-CA"
            @lang = ["en-CA", "fr-CA"]
        end
    end


    POLITICAL_BUCKETS = {
    "liberal" => {
        segment: [
            "US politics (liberal)",  # segment
            "Likely to engage with political content (liberal)",  # segment
            "US politics (very liberal)",  # segment
        ],
        interest: [
            "Democratic Party (United States)",
            "Bernie Sanders",
            "Barack Obama",
            "Environmentalism",
            "Planned Parenthood",
            "Elizabeth Warren",
            "The People For Bernie Sanders",
            "The Young Turks",
            "MoveOn.org",
            "NPR",
            "Feminism",
            "Black Lives Matter",
            "Social justice",
            "Kamala Harris",
            "Hillary Clinton",
            "The New York Times",
            "Woke Folks",
            "Left-wing politics",
            "Climate change",
            "DREAM Act",
            "EMILY's List",
            "Mother Jones (magazine)",
        ]
    },
    "apolitical" => {
        segment: [
            "US politics (moderate)",
            "Likely to engage with political content (moderate)",
        ],
        interest: [
            "Politics and social issues",
            "Politics",
            "Education",
            "Community issues",
            "Higher education",
            "Charity and causes",
            "Nonprofit organization",
            "Current events",
            "Nature",
            "Natural environment",
            "Environmental science",
            "Federal government of the United States",
            "National Park Service",
            "Mountains",
            "Business",
            "Fitness and wellness",
            "Family",
            "Volunteering",
            "Health system",
            "Medicare (United States)",
            "Technology",
            "Teacher",
            "Local government",
            "Family and relationships",
            "Supreme Court of the United States",
            "Business and industry",
            "Health care"

        ]
    },
    "conservative" => {
        segment: [
            "Likely to engage with political content (conservative)",
            "US politics (conservative)",
            "US politics (very conservative)",
        ],
        interest: [
            "Republican Party (United States)",
            "Ted Cruz",
            "Donald Trump",
            "Fox News Channel",
            "National Rifle Association"
        ]
    }
    }    

end