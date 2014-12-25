# encoding: utf-8
module Rhinoart
	class BaseController < ApplicationController
		include SessionsHelper
		before_filter :check_if_user_has_admin_role
		

		rescue_from CanCan::AccessDenied do |exception|
			if user_signed_in?
				if !can? :access, :admin_panel
					redirect_to main_app.root_path, alert: exception.message
				else
					flash.now[:info] = "Access denied."
					render :template => 'rhinoart/shared/no_approved', :status => 403
				end
			else
				redirect_to new_user_session_path, alert: exception.message
			end
		end


		private    
			def check_if_user_has_admin_role
				authorize! :access, :admin_panel
			end


	end
end
