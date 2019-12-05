class WritablePagesController < ApplicationController
  def update
    @writable_page = WritablePage.find_or_initialize_by(page_id: params[:page_id], disclaimer: params[:disclaimer])
    @writable_page.notes = params[:notes]
    @writable_page.save

    respond_to do |format|
      format.json { render json: {
          ok: "ok"
        }
      }
    end
  end
end
