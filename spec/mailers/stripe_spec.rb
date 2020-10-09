RSpec::Benchmark.configure do |config|
  config.run_in_subprocess = true
end

RSpec.describe StripeMailer, type: :mailer do
  let(:new_stripe_mail) { StripeMailer.notify_orphan_payment_intent_to_cancel('pi_testing123with123rspec') }

  describe 'notify_orphan_payment_intent_to_cancel' do
    it 'renders the subject' do
      expect(new_stripe_mail.subject).to eql('Cancel authorization of Stripe Payment Intent')
    end

    it 'renders the receiver email' do
      expect(new_stripe_mail.to).to eql(['george@kattbnb.se'])
    end

    it 'renders the sender email' do
      expect(new_stripe_mail.from).to eql('KattBNB meow-reply')
    end

    it 'contains the payment intent to cancel' do
      expect(new_stripe_mail.body.encoded).to match('pi_testing123with123rspec')
    end

    it 'is performed under 500ms' do
      expect { new_stripe_mail }.to perform_under(500).ms.sample(20).times
    end

    it 'performs at least 800K iterations per second' do
      expect { new_stripe_mail }.to perform_at_least(800000).ips
    end
  end
end