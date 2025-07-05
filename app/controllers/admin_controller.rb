class AdminController < ApplicationController
  before_action :require_admin

  private

  def require_admin
    redirect_to "/" unless Current.session&.user&.admin?
  end
end
