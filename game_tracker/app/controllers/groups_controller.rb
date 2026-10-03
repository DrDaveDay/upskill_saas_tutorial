class GroupsController < ApplicationController
  before_action :set_group, only: %i[ show edit update regenerate_invite ]
  before_action :require_admin, only: %i[ edit update regenerate_invite ]

  def show
    @month = selected_month
    @current_month = @month == Date.current.beginning_of_month
    @leaderboard = Leaderboard.for_month(@group, @month)
    @prize = @group.prize_for(@month)
    @today = Leaderboard.for_day(@group, Date.current) if @current_month
    @today_results = Result.where(user: @group.members, played_on: Date.current).group_by(&:user_id) if @current_month
    @admin = @group.admin?(current_user)
  end

  def new
    @group = Group.new
  end

  def create
    @group = Group.new(group_params)
    if @group.valid?
      @group = Group.create_with_admin!(current_user, group_params)
      redirect_to edit_group_path(@group), notice: "Group created! Set this month's prize and share the invite link."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @this_month = Date.current.beginning_of_month
    @next_month = @this_month.next_month
    @memberships = @group.memberships.includes(:user).order("users.name")
  end

  def update
    if @group.update(group_params)
      redirect_to edit_group_path(@group), notice: "Group renamed."
    else
      redirect_to edit_group_path(@group), alert: @group.errors.full_messages.to_sentence
    end
  end

  def regenerate_invite
    @group.regenerate_invite_code!
    redirect_to edit_group_path(@group), notice: "New invite link created. The old one no longer works."
  end

  private
    def set_group
      @group = current_user.groups.find(params[:id])
    end

    def require_admin
      redirect_to group_path(@group), alert: "Only group admins can do that." unless @group.admin?(current_user)
    end

    def group_params
      params.expect(group: [ :name ])
    end

    def selected_month
      Date.strptime(params[:month].to_s, "%Y-%m")
    rescue Date::Error
      Date.current.beginning_of_month
    end
end
