class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_filter :check_uri
  before_action :set_locale
  before_filter :update_sanitized_params, if: :devise_controller?

  include ApplicationHelper

  def check_uri
    if Rails.configuration.redirect_to_www
      redirect_to request.protocol + "www." + request.host_with_port + request.fullpath if !/^www/.match(request.host)
    end
  end

  def set_locale
    if current_user.present? && current_user.locales.present? && current_user.locales.count == 1
      I18n.locale = params[:locale] || current_user.locales.first || I18n.default_locale
    else
      I18n.locale = params[:locale] || I18n.default_locale
    end
  end

  private

  # To permit simple scalar values, use this
  def update_sanitized_params
    devise_parameter_sanitizer.for(:sign_up) { |u| u.permit(:name, :email, :password, :password_confirmation) }
  end
end
