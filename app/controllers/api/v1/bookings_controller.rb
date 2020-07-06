class Api::V1::BookingsController < ApplicationController
  
  before_action :authenticate_api_v1_user!, only: [:index, :create, :update]

  def index
    if params[:stats] == 'yes' && params[:host_nickname] == current_api_v1_user.nickname && params[:user_id].to_i == current_api_v1_user.id
      now = DateTime.new(Time.now.year, Time.now.month, Time.now.day, 0, 0, 0, 0)
      now_epoch_javascript = (now.to_f * 1000).to_i
      incoming_bookings = Booking.where(host_nickname: params[:host_nickname])
      incoming_requests = []
      incoming_upcoming = []
      incoming_history = []
      incoming_bookings.each do |booking|
        if booking.status == 'pending'
          incoming_requests.push(booking)
        elsif booking.status == 'accepted' && booking.dates.last > now_epoch_javascript
          incoming_upcoming.push(booking)
        else
          incoming_history.push(booking)
        end
      end
      outgoing_bookings = Booking.where(user_id: params[:user_id])
      outgoing_requests = []
      outgoing_upcoming = []
      outgoing_history = []
      outgoing_bookings.each do |booking|
        if booking.status == 'pending'
          outgoing_requests.push(booking)
        elsif booking.status == 'accepted' && booking.dates.last > now_epoch_javascript
          outgoing_upcoming.push(booking)
        else
          outgoing_history.push(booking)
        end
      end
      render json: { message: "in_requests: #{incoming_requests.length}, in_upcoming: #{incoming_upcoming.length}, in_history: #{incoming_history.length}, out_requests: #{outgoing_requests.length}, out_upcoming: #{outgoing_upcoming.length}, out_history: #{outgoing_history.length}" }, status: 200
    elsif params[:stats] == 'no' && params[:host_nickname] == current_api_v1_user.nickname
      bookings = Booking.where(host_nickname: params[:host_nickname])
      render json: bookings, each_serializer: Bookings::IndexSerializer
    elsif params[:stats] == 'no' && params[:user_id].to_i == current_api_v1_user.id
      bookings = Booking.where(user_id: params[:user_id])
      render json: bookings, each_serializer: Bookings::IndexSerializer
    else
      bookings = []
      render json: bookings, each_serializer: Bookings::IndexSerializer
    end
  end

  def create
    booking = Booking.create(booking_params)
    if booking.persisted?
      host = User.where(nickname: booking.host_nickname)
      if host.length == 1
        profile = HostProfile.where(user_id: host[0].id)
        user = User.where(id: booking.user_id)
        if (booking.dates - profile[0].availability).empty? == true
          render json: { message: I18n.t('controllers.reusable.create_success') }, status: 200
          new_availability = profile[0].availability - booking.dates
          profile.update(availability: new_availability)
          BookingsMailer.delay(:queue => 'bookings_email_notifications').notify_host_create_booking(host[0], booking, user[0])
        else
          booking.update(status: 'canceled')
          booking.destroy
          render json: { error: [I18n.t('controllers.bookings.create_error_1')] }, status: 422
        end
      else
        booking.destroy
        render json: { error: [I18n.t('controllers.bookings.create_error_2')] }, status: 422
      end
    else
      render json: { error: booking.errors.full_messages }, status: 422
    end
  end

  def update
    booking = Booking.find(params[:id])
    if current_api_v1_user.nickname == booking.host_nickname
      user = User.where(id: booking.user_id)
      host = User.where(nickname: booking.host_nickname)
      profile = HostProfile.where(user_id: host[0].id)
      booking.update(status: params[:status], host_message: params[:host_message])
      if booking.persisted? == true && booking.host_message.length < 201 && booking.status == 'accepted'
        render json: { message: I18n.t('controllers.bookings.update_success') }, status: 200
        booking.update(host_description: profile[0].description, host_full_address: profile[0].full_address, host_real_lat: profile[0].latitude, host_real_long: profile[0].longitude)
        BookingsMailer.delay(:queue => 'bookings_email_notifications').notify_user_accepted_booking(host[0], booking, user[0])
      elsif booking.persisted? == true && booking.host_message.length < 201 && booking.status == 'declined'
        new_availability = (profile[0].availability + booking.dates).sort
        profile.update(availability: new_availability)
        render json: { message: I18n.t('controllers.bookings.update_success') }, status: 200
        BookingsMailer.delay(:queue => 'bookings_email_notifications').notify_user_declined_booking(host[0], booking, user[0])
      else
        render json: { error: booking.errors.full_messages }, status: 422
      end
    else
      render json: { error: I18n.t('controllers.reusable.update_error') }, status: 422
    end

  rescue ActiveRecord::RecordNotFound
    render json: { error: [I18n.t('controllers.bookings.update_error')] }, status: :not_found
  end

 
  private

  def booking_params
    params.permit(:number_of_cats, :message, :host_nickname, :price_per_day, :price_total, :user_id, :dates => [])
  end

end
