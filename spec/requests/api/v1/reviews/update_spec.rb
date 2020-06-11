RSpec::Benchmark.configure do |config|
  config.run_in_subprocess = true
end

RSpec.describe Api::V1::ReviewsController, type: :request do
  let(:user1) { FactoryBot.create(:user, email: 'chaos@thestreets.com', nickname: 'Joker') }
  let(:user2) { FactoryBot.create(:user, email: 'morechaos@thestreets.com', nickname: 'Harley Quinn') }
  let(:user3) { FactoryBot.create(:user, email: 'order@thestreets.com', nickname: 'Batman') }
  let!(:profile1) { FactoryBot.create(:host_profile, user_id: user2.id) }
  let!(:profile2) { FactoryBot.create(:host_profile, user_id: user3.id) }
  let!(:booking1) { FactoryBot.create(:booking, user_id: user1.id) }
  let!(:booking2) { FactoryBot.create(:booking, user_id: user2.id) }
  let(:review1) { FactoryBot.create(:review, host_nickname: 'Harley Quinn', user_id: user1.id, host_profile_id: profile1.id, booking_id: booking1.id) }
  let(:review2) { FactoryBot.create(:review, host_nickname: 'Batman', user_id: user2.id, host_profile_id: profile2.id, booking_id: booking2.id) }
  let(:credentials1) { user1.create_new_auth_token }
  let(:credentials2) { user2.create_new_auth_token }
  let(:headers1) { { HTTP_ACCEPT: "application/json" }.merge!(credentials1) }
  let(:headers2) { { HTTP_ACCEPT: "application/json" }.merge!(credentials2) }
  let(:not_headers) { {HTTP_ACCEPT: "application/json"} }

  describe 'PATCH /api/v1/reviews/id' do

    describe 'successfully' do
      before do
        patch "/api/v1/reviews/#{review1.id}", params: {
          host_reply: 'Thanks a lot!'
        },
        headers: headers2
      end

      it 'updates a specific review' do
        expect(json_response).to eq 'Succesfully updated!'
      end

      it 'has correct response status' do
        expect(response.status).to eq 200
      end
    end

    describe 'unsuccessfully' do
      it 'cannot update a review if not logged in' do
        patch "/api/v1/reviews/#{review1.id}", params: {
          host_reply: 'Thanks a lot!'
        },
        headers: not_headers
        expect(response.status).to eq 401
        expect(json_response['errors']).to eq ['You need to sign in or sign up before continuing.']
      end

      it 'cannot update a review that she is not a part of' do
        patch "/api/v1/reviews/#{review2.id}", params: {
          host_reply: 'Thanks a lot!'
        },
        headers: headers2
        expect(response.status).to eq 422
        expect(json_response['error']).to eq ['You cannot perform this action!']
      end

      it 'cannot update a review that already contains a host_reply' do
        review1.update(host_reply: 'Already updated!')
        patch "/api/v1/reviews/#{review1.id}", params: {
          host_reply: 'Thanks a lot!'
        },
        headers: headers2
        expect(response.status).to eq 422
        expect(json_response['error']).to eq ['You cannot perform this action!']
      end

      it 'cannot update a review if user has deleted her account' do
        review1.update(user_id: nil, booking_id: nil)
        patch "/api/v1/reviews/#{review1.id}", params: {
          host_reply: 'Thanks a lot!'
        },
        headers: headers2
        expect(response.status).to eq 422
        expect(json_response['error']).to eq ['You cannot perform this action!']
      end
    end

    describe 'performance wise' do
      it 'updates a review in under 1 ms and with iteration rate of 5000000 per second' do
        patch_request = patch "/api/v1/reviews/#{review1.id}", params: {
          host_reply: 'Thanks a lot!'
        },
        headers: headers2
        expect { patch_request }.to perform_under(1).ms.sample(20).times
        expect { patch_request }.to perform_at_least(5000000).ips
      end
    end
  end
end
