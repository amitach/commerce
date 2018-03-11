class ApplicationController < ActionController::Base
  rescue_from AppError do | ex |
    flash[:error] = ex.message
    render ex.action
  end
end
