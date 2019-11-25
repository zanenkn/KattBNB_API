RSpec.describe Api::V1::BookingsController, type: :request do
  let(:user) { FactoryBot.create(:user) }
  let!(:user2) { FactoryBot.create(:user, email: 'chaos@thestreets.com', nickname: 'Joker', location: 'Athens') }
  let!(:user3) { FactoryBot.create(:user, email: 'morechaos@thestreets.com', nickname: 'JJoker', location: 'Athens') }
  let(:credentials) { user.create_new_auth_token }
  let(:headers) { { HTTP_ACCEPT: "application/json" }.merge!(credentials) }
  let(:not_headers) { {HTTP_ACCEPT: "application/json"} }

  describe 'POST /api/v1/booking' do

    describe 'successfully' do
      before do
        post '/api/v1/bookings', params: {
          number_of_cats: '2',
          message: 'Take my cat, pls!',
          host_nickname: 'Joker',
          dates: [1562803200000, 1562889600000, 1562976000000, 1563062400000, 1563148800000],
          price_per_day: '258.36',
          price_total: '1856',
          user_id: user.id
        }, 
        headers: headers
      end

      it 'creates a booking' do
        expect(json_response['message']).to eq 'Successfully created'
        expect(response.status).to eq 200
      end

      it 'sends an email upon booking creation' do
        expect(ActionMailer::Base.deliveries.count).to eq 1
      end

      it 'creates another booking and sends a second email' do
        post '/api/v1/bookings', params: {
          number_of_cats: '23',
          message: 'I want my cats to have a good time, pls!',
          host_nickname: 'JJoker',
          dates: [1562803200000, 1562889600000],
          price_per_day: '125.96',
          price_total: '1452.36',
          user_id: user.id
        }, 
        headers: headers

        expect(json_response['message']).to eq 'Successfully created'
        expect(response.status).to eq 200
        expect(user.booking.length).to eq 2
        expect(ActionMailer::Base.deliveries.count).to eq 2
      end
    end

    describe 'unsuccessfully' do
      it 'Booking can not be created without all fields filled in' do
        post '/api/v1/bookings', params: {
          number_of_cats: '2',
          host_nickname: 'George',
          dates: [1562803200000, 1562889600000, 1562976000000, 1563062400000, 1563148800000],
          price_per_day: '105.96',
          price_total: '1400.36',
          user_id: user.id
        }, 
        headers: headers

        expect(json_response['error']).to eq ["Message can't be blank"]
        expect(response.status).to eq 422
      end

      it 'Booking can not be created if message is more than 400 characters in length' do
        post '/api/v1/bookings', params: {
          number_of_cats: '2',
          host_nickname: 'George',
          dates: [1562803200000, 1562889600000, 1562976000000, 1563062400000, 1563148800000],
          price_per_day: '105.96',
          price_total: '1400.36',
          user_id: user.id,
          message: "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum."
        }, 
        headers: headers

        expect(json_response['error']).to eq ['Message is too long (maximum is 400 characters)']
        expect(response.status).to eq 422
      end

      it 'Booking can not be created if user is not logged in' do
        post '/api/v1/bookings', headers: not_headers
        expect(json_response['errors']).to eq ['You need to sign in or sign up before continuing.']
      end
    end
  end
end
