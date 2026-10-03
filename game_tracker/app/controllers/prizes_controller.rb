class PrizesController < ApplicationController
  def update
    group = current_user.groups.find(params[:group_id])
    return redirect_to(group_path(group), alert: "Only group admins can set the prize.") unless group.admin?(current_user)

    attrs = params.expect(prize: %i[ month description ])
    month = Date.parse(attrs[:month]).beginning_of_month
    prize = group.prizes.find_or_initialize_by(month: month)

    if attrs[:description].blank?
      prize.destroy if prize.persisted?
      redirect_to edit_group_path(group), notice: "Prize for #{month.strftime("%B")} cleared."
    elsif prize.update(description: attrs[:description])
      redirect_to edit_group_path(group), notice: "Prize for #{month.strftime("%B")} saved."
    else
      redirect_to edit_group_path(group), alert: prize.errors.full_messages.to_sentence
    end
  rescue Date::Error
    redirect_to edit_group_path(group), alert: "That month doesn't look right."
  end
end
