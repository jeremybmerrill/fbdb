class ApplicationController < ActionController::Base
  before_action :authenticate_user!
	protect_from_forgery with: :exception


  protected

  def force_trailing_slash
    redirect_to request.original_url + '/' unless request.original_url.match(/\/$/)
  end
end