class AdminController < ApplicationController
  before_action :require_admin

  private

  def require_admin
    redirect_to root_path unless Current.session&.user&.admin?
  end

  def default_url_options
    super.except(:server_id)
  end
end
