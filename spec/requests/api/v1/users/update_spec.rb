RSpec::Benchmark.configure do |config|
  config.run_in_subprocess = true
end

RSpec.describe 'User Saves / Changes Avatar and API', type: :request do
  let(:headers) { { HTTP_ACCEPT: 'application/json' } }

  it 'returns a user and a token and then saves the avatar' do

    post '/api/v1/auth', params: { email: 'felix@craft.se',
                                   password: 'password',
                                   password_confirmation: 'password',
                                   nickname: 'FlavioB',
                                   location: 'Tokyo',
                                   confirm_success_url: 'confirmed'
                                }, headers: headers
    
    User.last.update_attribute(:confirmed_at, '2019-08-10 09:56:34.588757')

    post "/api/v1/auth/sign_in", params: { email: 'felix@craft.se',
                                           password: 'password',
                                        }, headers: headers

    new_user_uid = response.headers['uid']
    new_user_token = response.headers['access-token']
    new_user_client = response.headers['client']
    new_user_id = json_response['data']['id']

    put "/api/v1/users/#{new_user_id}", params: {
                                  profile_avatar: {
                                        type: "image/png",
                                        encoder: "name=carbon (5).png;base64",
                                        data: "iVBORw0KGgoAAAANSUhEUgAABjAAAAOmCAYAAABFYNwHAAAgAElEQVR4XuzdB3gU1cLG8Te9EEgISQi9I71KFbBXbFixN6zfvSiIjSuKInoVFOyIDcWuiKiIol4Q6SBVOtI7IYSWBkm+58y6yW4a2SS7O4n/eZ7vuWR35pwzvzO76zf",
                                        extension: "png" 
                                      },
                                  'access-token': new_user_token,
                                  client: new_user_client
                               }, headers: headers
                               binding.pry
    expect(json_response['status']).to eq 'success'
    expect(response.status).to eq 200
    expect(json_response['data']['avatar']).to eq 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAQAAAAEACAYAAABccqhmAABMbklEQVR42u1deXycVdV+7n1nSSaTvUnaJk33j'
  end


















  

  it 'returns a user and a token and then saves the avatar in under 1 ms and with iteration rate of 5000000 per second' do

    post '/api/v1/auth', params: { email: 'felix@craft.se',
                                   password: 'password',
                                   password_confirmation: 'password',
                                   nickname: 'FlavioB',
                                   location: 'Tokyo',
                                   confirm_success_url: 'confirmed'
                                }, headers: headers
    
    User.last.update_attribute(:confirmed_at, '2019-08-10 09:56:34.588757')

    post "/api/v1/auth/sign_in", params: { email: 'felix@craft.se',
                                           password: 'password',
                                        }, headers: headers

    new_user_uid = response.headers['uid']
    new_user_token = response.headers['access-token']
    new_user_client = response.headers['client']
    new_user_id = json_response['data']['id']

    put_request = put '/api/v1/auth', params: { avatar: 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAQAAAAEACAYAAABccqhmAABMbklEQVR42u1deXycVdV+7n1nSSaTvUnaJk33j',
                                                uid: new_user_uid,
                                               'access-token': new_user_token,
                                                client: new_user_client
                                             }, headers: headers
    expect { put_request }.to perform_under(1).ms.sample(20).times
    expect { put_request }.to perform_at_least(5000000).ips
  end
end
