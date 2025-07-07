class ApplicationController < ActionController::Base
  include Authentication
  include NoticeI18n
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  private

  # Mission Control Jobs adds server_id to URL generation. Strip it for non-jobs routes.
  def default_url_options
    options = super || {}
    options.except(:server_id)
  end
end
