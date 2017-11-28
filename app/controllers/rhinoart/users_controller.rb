require_dependency "rhinoart/application_controller"

module Rhinoart
  class UsersController < BaseController
    before_action { authorize! :manage, :users }
    before_action :set_user, only: [:show, :edit, :update, :destroy]

    def index
      order_str = params[:sort].present? ? "#{params[:sort]} #{params[:dir]}" : 'name, email'

      @users = if params[:role].present?
                 case params[:role]
                 when 'new'
                   Rhinoart::User.where(approved: false).paginate(page: params[:page], per_page: 30).order(order_str)

                 when 'admin'
                   # @users = []
                   # User::ADMIN_PANEL_ROLES.each do |r|
                   # 	@users << User.with_any_role(r)
                   # end
                   # @users = @users[0]
                   # @users = User.where("approved = 1 and (admin_role is not null or admin_role != '')").paginate(page: params[:page], per_page: 30).order(order_str)

                   Rhinoart::User.admin_users.paginate(page: params[:page], per_page: 30).order(order_str)
                 # User.joins(:rhinoart_users_roles, :roles).where(approved: true, roles: {name: User::ADMIN_PANEL_ROLES}).group(:email).paginate(page: params[:page], per_page: 30).order(order_str)
                 else
                   Rhinoart::User.all.paginate(page: params[:page], per_page: 30).order(order_str)
                 end
               else
                 if params[:q].present?
                   Rhinoart::User.where('email LIKE ? or info LIKE ?', "%#{params[:q]}%", "%#{params[:q]}%").paginate(page: params[:page], per_page: 30).order(order_str)
                 else
                   Rhinoart::User.paginate(page: params[:page], per_page: 30).order(order_str)
                 end
               end
    end

    def show
      @works = PaperTrail::Version.where(whodunnit: @user).order(created_at: :desc).paginate(:page => params[:page], :per_page => 40)
    end

    def new
      @user = Rhinoart::User.new
    end

    def create
      @user = User.new(user_attributes)
      if @user.save
        confirm
        flash[:success] = t("_WELCOME")
        redirect_to users_path
      else
        render 'new'
      end
    end

    def edit
    end

    def update
      new_attributes = user_attributes.to_hash.symbolize_keys
      new_attributes.delete(:password) if new_attributes[:password].blank?

      # if new_attributes[:approved] && !new_attributes[:email].present?
      # else
      #   new_attributes[:admin_roles] = nil if !new_attributes[:admin_roles].present? && can?(:manage, :all)
      #   begin
      #   		@user.api_role
      #   		new_attributes[:api_role] = nil if !new_attributes[:api_role].present? && can?(:manage, :all)
      #   rescue
      #   end
      # end

      confirm

      if @user.update_attributes(new_attributes)
        redirect_to (params[:redirect_to] || :users), success: "User created"
      else
        render :edit
      end
    end

    def destroy
      if params[:hard_delete]
        @user.destroy
      else
        if params[:clear_rights].present?
          @user.roles.each do |role|
            @user.remove_role role.name rescue 1
          end
        end
        @user.update(approved: false)
      end

      redirect_to (params[:redirect_to] || :users), success: "User soft deleted"
    end

    private

    def confirm
      @user.confirmed_at = DateTime.now if @user.respond_to?(:confirmed_at) && @user.confirmed_at.nil?
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = Rhinoart::User.find(params[:id])
    rescue
      render template: 'rhinoart/shared/error404', status: :not_found
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def user_attributes
      params.require(:user).permit!
    end
  end
end
