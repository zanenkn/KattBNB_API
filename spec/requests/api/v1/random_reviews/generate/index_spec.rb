RSpec.describe 'GET /api/v1/random_reviews/generate', type: :request do
  describe 'successfully: when more than 2 reviews exist' do
    before do
      3.times { FactoryBot.create(:review, score: 5) }
      $low_score_review = FactoryBot.create(:review)
      $deleted_host_review = FactoryBot.create(:review)
      $deleted_host_review.update_attribute(:host_profile_id, nil)
      $deleted_host_review.reload
      get '/api/v1/random_reviews/generate'
    end

    it 'with 200 status' do
      expect(response.status).to eq 200
    end

    it 'with correct number of reviews' do
      expect(json_response.length).to eq 3
    end

    it 'with only 5 paw reviews' do
      json_response.each { |review| expect(review['id']).not_to eq $low_score_review.id }
    end

    it 'without reviews where host is deleted' do
      json_response.each { |review| expect(review['id']).not_to eq $deleted_host_review.id }
    end
  end

  describe 'unsuccessfully: when less than 3 reviews exist' do
    before { get '/api/v1/random_reviews/generate' }

    it 'with 404 status' do
      expect(response.status).to eq 404
    end

    it 'with relevant error' do
      expect(json_response['error']).to eq 'Not enough 5 paw reviews!'
    end
  end
end
