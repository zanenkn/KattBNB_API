class Api::V1::ReviewsController < ApplicationController
  
  before_action :authenticate_api_v1_user!, only: [:create]

  def create
    now = DateTime.new(Time.now.year, Time.now.month, Time.now.day, 0, 0, 0, 0)
    now_epoch_javascript = (now.to_f * 1000).to_i
    review = Review.create(review_params)
    if review.persisted?
      booking = Booking.find(params[:booking_id])
      if current_api_v1_user.id == booking.user_id && booking.dates.last < now_epoch_javascript
        render json: { message: I18n.t('controllers.reusable.create_success') }, status: 200
      else
        review.destroy
        render json: { error: [I18n.t('controllers.reusable.update_error')] }, status: 422
      end
    else      
      render json: { error: review.errors.full_messages }, status: 422
    end
  end

 
  private

  def review_params
    params.permit(:score, :body, :host_nickname, :user_id, :booking_id, :host_profile_id)
  end

end