class HomeController < ApplicationController
  allow_unauthenticated_access

  def show
    return render :landing unless authenticated?

    @groups = current_user.groups.order(:name)
    @today_results = current_user.results.on(Date.current).index_by(&:game)
  end
end
