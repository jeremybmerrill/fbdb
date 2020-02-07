Rails.application.routes.draw do
  devise_for :users
  get 'writable_pages/update'
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html

  root to: "ads#overview"

  get "payers", to: "payers#index"
  get "payers/:id", to: "payers#show"

  get "pages", to: "pages#index"
  get "pages/:id", to: "pages#show"
  get "pages_by_name/:page_name", to: "pages#show", :page_name => /[^\/]+(?=\.html\z|\.json\z)|[^\/]+/

  put "writable_pages/:page_id", to: 'writable_pages#update'
  get "topics", to: "ads#topics"

  get "ads", to: "ads#index"
  get "ads/search/", to: "ads#search"
  get "ads/:archive_id", to: "ads#show"
  get "ads_by_ad_id/:ad_id", to: "ads#show"
  get "ads_by_archive_id/:archive_id", to: "ads#show"
  get "ads_by_text/:text_hash", to: "ads#show_by_text"

  get "bigspenders", to: "pages#new_since_about_a_week_ago"


  get "interim/youtube/", to: "youtube#index"
  get "interim/youtube/advertiser/:targ", to: "youtube#advertiser"
  get 'interim/youtube/targeting/:targ', to: "youtube#targeting"
  get 'interim/youtube/targeting_all/:targ', to: "youtube#targeting_all"
  get 'interim/youtube/advertiser_all/:targ', to: "youtube#advertiser_all"
end
