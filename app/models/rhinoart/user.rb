# == Schema Information
#
# Table name: users
#
#  id              :integer          not null, primary key
#  name            :string(250)
#  email           :string(100)      not null
#  active          :boolean          default(TRUE), not null
#  roles           :string(255)      default("ROLE_USER"), not null
#  password_digest :string(255)
#  remember_token  :string(255)
#  created_at      :datetime
#  updated_at      :datetime
#

module Rhinoart
  class User < ActiveRecord::Base
    # Include default devise modules. Others available are:
    devise :database_authenticatable, :recoverable, :registerable, :trackable, :validatable

    before_save { |user| user.email = email.downcase }
    before_save :create_remember_token
    before_save :join_admin_roles
    after_initialize :split_admin_role


    # validates :name,  length: { :in => 3..50 }

    VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
    validates :email, format: { with: VALID_EMAIL_REGEX }, uniqueness: { case_sensitive: false }

    # validates :password, confirmation: true, length: { :in => 3..50 }#, :on => :create
    # validates :password_confirmation, presence: true#, :on => :create

    ADMIN_PANEL_ROLE_SUPER_USER = "Super User"
    ADMIN_PANEL_ROLE_USERS_MANAGER = "Users Manager"
    ADMIN_PANEL_ROLE_CONTENT_MANAGER = "Content Manager"
    ADMIN_PANEL_ROLES = [ADMIN_PANEL_ROLE_USERS_MANAGER, ADMIN_PANEL_ROLE_CONTENT_MANAGER, ADMIN_PANEL_ROLE_SUPER_USER]

    FRONTEND_ROLE_REPRESENTATIVE = "Representative"
    FRONTEND_ROLE_DOCTOR = "Doctor"
    FRONTEND_ROLES = [FRONTEND_ROLE_DOCTOR, FRONTEND_ROLE_REPRESENTATIVE]


    def name_email
      "#{self.name } (#{self.email})"    
    end


    def has_access_to_admin_panel?
        res = false
        begin
            ADMIN_PANEL_ROLES.each do |role|
                #db_roles = admin_role.split(',')
                return (admin_role.include? role) if (admin_role.include? role) == true
            end
        rescue
            return false
        end
        return res
    end
    alias_method :admin?, :has_access_to_admin_panel?

    def has_admin_role?(role)
        admin_role.include? role.to_s if admin_role.present?    
    end  


    private

      def create_remember_token
        self.remember_token = SecureRandom.urlsafe_base64 if !self.remember_token.present?
      end

    def join_admin_roles
      if self.admin_role.kind_of?(Array)
        self.admin_role.reject! { |ar| ar.empty? }
        self.admin_role = self.admin_role.join(',')
      end
    end

    def split_admin_role
      self.admin_role = self.admin_role.split(',') if self.admin_role.present?
    end
  end
end
