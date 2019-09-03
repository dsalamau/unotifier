RSpec.describe UNotifier::Provider::ProviderBase do
  describe "#can_notify?" do
    let(:valid_conditions) { [-> (n) { return true }] }
    let(:invalid_conditions) { [->(n) { return false }] }

    subject { provider.can_notify?(double("notification")) }

    context "when all conditions are valid" do
      let(:provider) { UNotifier::Provider::ProviderBase.new(notification_conditions: valid_conditions)}
      it { is_expected.to be_truthy }
    end

    context "when one of conditions is invalid" do
      let(:provider) { UNotifier::Provider::ProviderBase.new(notification_conditions: valid_conditions + invalid_conditions)}
      it { is_expected.to be_falsy }
    end
  end
end
