class Bookings::IndexSerializer < ActiveModel::Serializer
  attributes :id,
             :number_of_cats,
             :dates,
             :status,
             :host_id,
             :host_profile_id,
             :host_profile_score,
             :host_location,
             :host_nickname,
             :message,
             :price_total,
             :host_message,
             :host_avatar,
             :host_description,
             :host_full_address,
             :host_real_lat,
             :host_real_long,
             :created_at,
             :updated_at,
             :user_id,
             :review_id

  belongs_to :user, serializer: Users::BookingsSerializer

  def host_id
    host = User.find_by(nickname: object.host_nickname)
    return host.id unless host.nil?
  end

  def host_profile_id
    host = User.find_by(nickname: object.host_nickname)
    unless host.nil?
      host_profile = HostProfile.find_by(user_id: host.id)
      return host_profile.id unless host_profile.nil?
    end
  end

  def host_profile_score
    host = User.find_by(nickname: object.host_nickname)
    unless host.nil?
      host_profile = HostProfile.find_by(user_id: host.id)
      return host_profile.score unless host_profile.nil?
    end
  end

  def host_location
    host = User.find_by(nickname: object.host_nickname)
    return host.location unless host.nil?
  end

  def host_avatar
    host = User.find_by(nickname: object.host_nickname)
    return host.profile_avatar.attached? ? AttachmentService.get_blob_url(host) : nil unless host.nil?
  end

  def review_id
    return object.review.id unless object.review.nil?
  end
end
