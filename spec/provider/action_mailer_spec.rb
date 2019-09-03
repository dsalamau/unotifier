RSpec.describe UNotifier::Provider::ActionMailer do
  let(:sending_method) { :send_notification }
  let(:another_sending_method) { :send_another_notification }
  let(:mailer) { double("Mailer") }
  let(:email) { double("Email") }
  let(:notification) { double("Notification") }

  it { expect(UNotifier::Provider::ActionMailer).to be < UNotifier::Provider::ProviderBase }

  describe "#notify" do
    context "when sending method passed as array" do
      let(:provider) { UNotifier::Provider::ActionMailer.new(mailer, sending_method: [ -> (n) { :send_another_notification }]) }

      it "should call provided sending_method on mailer with notification argument" do
        expect(email).to receive(:deliver)
        expect(mailer).to receive(another_sending_method).with(notification).and_return(email)
        provider.notify(notification)
      end
    end

    context "when sending method passed as symbol" do
      let(:provider) { UNotifier::Provider::ActionMailer.new(mailer, sending_method: sending_method) }

      it "should call provided sending_method on mailer with notification argument" do
        expect(email).to receive(:deliver)
        expect(mailer).to receive(sending_method).with(notification).and_return(email)
        provider.notify(notification)
      end
    end
  end
end
