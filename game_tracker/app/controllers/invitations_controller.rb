class InvitationsController < ApplicationController
  allow_unauthenticated_access only: :show
  before_action :set_group

  def show
    if authenticated?
      redirect_to group_path(@group) if @group.member?(current_user)
    else
      # Bring people back here after they sign up or sign in.
      session[:return_to_after_authenticating] = invitation_url(@group.invite_code)
    end
  end

  def create
    @group.memberships.find_or_create_by!(user: current_user)
    redirect_to group_path(@group), notice: "You joined #{@group.name}!"
  end

  private
    def set_group
      @group = Group.find_by(invite_code: params[:code].to_s.upcase)
      redirect_to root_path, alert: "That invite link isn't valid anymore. Ask your group admin for a new one." unless @group
    end
end
