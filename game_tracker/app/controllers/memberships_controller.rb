class MembershipsController < ApplicationController
  before_action :set_group_and_membership

  # Admins can promote/demote members.
  def update
    return deny unless @group.admin?(current_user)

    role = params.expect(membership: [ :role ])[:role]
    if @membership.user == current_user && role != "admin" && @group.memberships.where(role: "admin").count == 1
      redirect_to edit_group_path(@group), alert: "You're the only admin. Make someone else an admin first."
    elsif @membership.update(role: role)
      redirect_to edit_group_path(@group), notice: "#{@membership.user.name} is now #{role == "admin" ? "an admin" : "a member"}."
    else
      redirect_to edit_group_path(@group), alert: @membership.errors.full_messages.to_sentence
    end
  end

  # Admins can remove anyone; members can remove themselves (leave).
  def destroy
    leaving = @membership.user == current_user
    return deny unless leaving || @group.admin?(current_user)

    if @membership.destroy
      @group.destroy if @group.memberships.reload.none?
      if leaving
        redirect_to root_path, notice: "You left #{@group.name}."
      else
        redirect_to edit_group_path(@group), notice: "#{@membership.user.name} was removed."
      end
    else
      redirect_back_or_to group_path(@group), alert: @membership.errors.full_messages.to_sentence
    end
  end

  private
    def set_group_and_membership
      @group = current_user.groups.find(params[:group_id])
      @membership = @group.memberships.find(params[:id])
    end

    def deny
      redirect_to group_path(@group), alert: "Only group admins can do that."
    end
end
