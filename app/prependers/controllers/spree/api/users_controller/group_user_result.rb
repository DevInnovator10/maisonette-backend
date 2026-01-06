# frozen_string_literal: true

module Spree::Api::UsersController::GroupUserResult
  def index
    user_scope = model_class.accessible_by(current_ability, :show)
    if params[:ids]
      ids = params[:ids].split(',').flatten
      @users = user_scope.where(id: ids).order(email: :asc)
    else

      @users = user_scope.ransack(params[:q]).result.group(:id)
    end

    @users = paginate(@users.distinct)
    respond_with(@users)
  end
end
