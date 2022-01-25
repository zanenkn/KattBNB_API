RSpec.describe 'PATCH /api/v1/reviews/id', type: :request do
  let(:customer) { FactoryBot.create(:user, email: 'chaos@thestreets.com', nickname: 'Joker') }
  let(:booking) { FactoryBot.create(:booking, user_id: customer.id) }

  let(:host) { FactoryBot.create(:user, email: 'morechaos@thestreets.com', nickname: 'Harley Quinn') }
  let(:host_credentials) { host.create_new_auth_token }
  let(:host_headers) { { HTTP_ACCEPT: 'application/json' }.merge!(host_credentials) }
  let(:host_profile) { FactoryBot.create(:host_profile, user_id: host.id) }

  let(:random_user) { FactoryBot.create(:user, email: 'order@thestreets.com', nickname: 'Batman') }
  let(:random_profile) { FactoryBot.create(:host_profile, user_id: random_user.id) }
  let(:random_booking) { FactoryBot.create(:booking, user_id: host.id) }

  let(:not_headers) { { HTTP_ACCEPT: 'application/json' } }

  let(:review) do
    FactoryBot.create(
      :review,
      host_nickname: 'Harley Quinn',
      host_reply: nil,
      user_id: customer.id,
      host_profile_id: host_profile.id,
      booking_id: booking.id
    )
  end

  let(:random_review) do
    FactoryBot.create(
      :review,
      host_nickname: 'Batman',
      host_reply: nil,
      user_id: host.id,
      host_profile_id: random_profile.id,
      booking_id: random_booking.id
    )
  end

  describe 'successfully ' do
    describe 'when user and host exist' do
      before { patch "/api/v1/reviews/#{review.id}", params: { host_reply: 'Thanks a lot!' }, headers: host_headers }

      it 'with relevant message' do
        expect(json_response['message']).to eq 'Successfully updated!'
      end

      it 'with 200 status' do
        expect(response.status).to eq 200
      end
    end

    describe 'even if the user who wrote the review has deleted their account' do
      before do
        review.update_attribute(:user_id, nil)
        review.update_attribute(:booking_id, nil)
        patch "/api/v1/reviews/#{review.id}", params: { host_reply: 'Thanks a lot!' }, headers: host_headers
        review.reload
      end

      it 'with 200 status' do
        expect(response.status).to eq 200
      end

      it 'with correct host reply' do
        expect(review.host_reply).to eq 'Thanks a lot!'
      end
    end
  end

  describe 'unsuccessfully' do
    describe 'if host is not logged in' do
      before { patch "/api/v1/reviews/#{review.id}", params: { host_reply: 'Thanks a lot!' }, headers: not_headers }

      it 'with relevant error' do
        expect(json_response['errors']).to eq ['You need to sign in or sign up before continuing.']
      end

      it 'with 401 status' do
        expect(response.status).to eq 401
      end
    end

    describe 'if host tries to update review they are not part of' do
      before do
        patch "/api/v1/reviews/#{random_review.id}", params: { host_reply: 'Thanks a lot!' }, headers: host_headers
      end

      it 'with relevant error' do
        expect(json_response['error']).to eq ['You cannot perform this action!']
      end

      it 'with 422 status' do
        expect(response.status).to eq 422
      end
    end

    describe 'if review has already been updated by the host' do
      before do
        review.update(host_reply: 'Already updated!')
        patch "/api/v1/reviews/#{review.id}", params: { host_reply: 'Thanks a lot!' }, headers: host_headers
      end

      it 'with relevant error' do
        expect(json_response['error']).to eq ['You cannot perform this action!']
      end

      it 'with 422 status' do
        expect(response.status).to eq 422
      end
    end
  end
end
