class Api::V1::UsersController < ApplicationController
  before_action :authenticate_api_v1_user!, only: [:update]

  def update
    user = User.find(params[:id])
    if current_api_v1_user.id == user.id && params[:profile_avatar] != nil
      pic = params[:profile_avatar]
      DecodeImageService.attach_image(pic, user.profile_avatar)
      user.update(avatar: pic[0])
      render json: { message: I18n.t('controllers.reusable.update_success') }, status: 200
    else
      render json: { error: [I18n.t('controllers.reusable.update_error')] }, status: 422
    end
  end
end
