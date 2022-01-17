RSpec.describe 'GET /api/v1/stripe', type: :request do
  let(:user) { FactoryBot.create(:user, email: 'george@mail.com', nickname: 'Alonso') }
  let(:profile_user) { FactoryBot.create(:host_profile, user_id: user.id) }
  let(:credentials) { user.create_new_auth_token }
  let(:headers) { { HTTP_ACCEPT: 'application/json' }.merge!(credentials) }

  let(:user2) { FactoryBot.create(:user, email: 'felix@mail.com', nickname: 'MacOS') }
  let(:profile_user2) { FactoryBot.create(:host_profile, user_id: user2.id, stripe_account_id: 'acct_wTfAyD65545$mf') }
  let(:credentials2) { user2.create_new_auth_token }
  let(:headers2) { { HTTP_ACCEPT: 'application/json' }.merge!(credentials2) }

  let(:not_headers) { { HTTP_ACCEPT: 'application/json' } }

  describe 'successfully' do
    describe 'no stripe account on retrieve request' do
      before { get "/api/v1/stripe?host_profile_id=#{profile_user.id}&occasion=retrieve", headers: headers }

      it 'with relevant message' do
        expect(json_response['message']).to eq 'No account'
      end

      it 'with 200 status' do
        expect(response.status).to eq 200
      end
    end

    describe 'no stripe account on delete request' do
      before { get "/api/v1/stripe?host_profile_id=#{profile_user.id}&occasion=delete_account", headers: headers }

      it 'with relevant message' do
        expect(json_response['message']).to eq 'No account'
      end

      it 'with 200 status' do
        expect(response.status).to eq 200
      end
    end
  end

  describe 'unsuccesfully' do
    describe 'for request of stripe profile details of another user' do
      before { get "/api/v1/stripe?host_profile_id=#{profile_user.id}&occasion=retrieve", headers: headers2 }

      it 'with relevant error' do
        expect(json_response['error']).to eq 'You cannot perform this action!'
      end

      it 'with 422 status' do
        expect(response.status).to eq 422
      end
    end

    describe 'if not authenticated and requests own stripe profile details' do
      before { get "/api/v1/stripe?host_profile_id=#{profile_user.id}&occasion=retrieve", headers: not_headers }

      it 'with relevant error' do
        expect(json_response['errors']).to eq ['You need to sign in or sign up before continuing.']
      end

      it 'with 401 status' do
        expect(response.status).to eq 401
      end
    end

    describe 'if user tries to request stripe dashboard link of another user' do
      before { get "/api/v1/stripe?host_profile_id=#{profile_user.id}&occasion=login_link", headers: headers2 }

      it 'with relevant error' do
        expect(json_response['error']).to eq 'You cannot perform this action!'
      end

      it 'with 422 status' do
        expect(response.status).to eq 422
      end
    end

    describe 'if not authenticated and requests stripe dashboard link' do
      before { get "/api/v1/stripe?host_profile_id=#{profile_user.id}&occasion=login_link", headers: not_headers }

      it 'with relevant error' do
        expect(json_response['errors']).to eq ['You need to sign in or sign up before continuing.']
      end

      it 'with 401 status' do
        expect(response.status).to eq 401
      end
    end

    describe 'if not authenticated and creates a stripe payment intent' do
      before { get '/api/v1/stripe?occasion=create_payment_intent', headers: not_headers }

      it 'with relevant error' do
        expect(json_response['errors']).to eq ['You need to sign in or sign up before continuing.']
      end

      it 'with 401 status' do
        expect(response.status).to eq 401
      end
    end

    describe 'if not authenticated and updates a stripe payment intent' do
      before { get '/api/v1/stripe?occasion=update_payment_intent', headers: not_headers }

      it 'with relevant error' do
        expect(json_response['errors']).to eq ['You need to sign in or sign up before continuing.']
      end

      it 'with 401 status' do
        expect(response.status).to eq 401
      end
    end

    describe 'if not authenticated and requests stripe account deletion' do
      before { get "/api/v1/stripe?host_profile_id=#{profile_user.id}&occasion=delete_account", headers: not_headers }

      it 'with relevant error' do
        expect(json_response['errors']).to eq ['You need to sign in or sign up before continuing.']
      end

      it 'with 401 status' do
        expect(response.status).to eq 401
      end
    end

    describe 'if user tries to request stripe account deletion of another user' do
      before { get "/api/v1/stripe?host_profile_id=#{profile_user.id}&occasion=delete_account", headers: headers2 }

      it 'with relevant error' do
        expect(json_response['error']).to eq 'You cannot perform this action!'
      end

      it 'with 422 status' do
        expect(response.status).to eq 422
      end
    end

    describe 'if user tries to request stripe account deletion of account that does not exist' do
      before { get "/api/v1/stripe?host_profile_id=#{profile_user2.id}&occasion=delete_account", headers: headers2 }

      it 'with relevant custom error' do
        expect(
          json_response['error']
        ).to eq 'There was a problem connecting to our payments infrastructure provider. Please try again later.'
      end

      it 'with 555 custom status' do
        expect(response.status).to eq 555
      end
    end
  end
end
