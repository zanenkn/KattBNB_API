class Api::V1::HostProfilesController < ApplicationController
  
  before_action :authenticate_api_v1_user!, only: [:create, :destroy, :update]


  def index
  end
  
  def create
    profile = HostProfile.create(host_profile_params)
    
    if profile.persisted?
      render json: { message: 'Successfully created' }, status: 200
    else
      render json: { error: profile.errors.full_messages }, status: 422
    end    
  end


  def update
    profile = HostProfile.find(params[:id])

    if current_api_v1_user.id == profile.user_id
      profile.update(host_profile_params)
      if profile.persisted? == true
        render json: { message: 'You have successfully updated your host profile' }, status: 200
      else
        render json: { error: 'There was a problem updating your host profile' }
      end
    else
      render json: { error: 'You cannot perform this action' }, status: 422
    end
  end


  def destroy
    profile = HostProfile.find(params[:id])
    
    if current_api_v1_user.id == profile.user_id && profile.present? == true && profile.destroyed? == false
      profile.destroy
      render json: { message: 'You have successfully deleted your host profile' }, status: 200
    else
      render json: { error: 'You cannot perform this action' }, status: 422
    end  
  end


  
  private

  def host_profile_params
    params.permit(:description, :full_address, :price_per_day_1_cat, :supplement_price_per_cat_per_day, :max_cats_accepted, :availability, :lat, :long, :latitude, :longitude, :user_id)
  end

end
