RSpec.describe UNotifier::Provider::ActionCable do
  let(:notification_attrs) do
    {
      id: 1,
      title: "title",
      body: "body",
      autohide_delay: "10",
      user_login: "login",
      link: "link",
      urgency: "regular"
    }
  end

  let(:target) { double("Target") }
  let(:notification) { double("Notification") }
  let(:server) { double("ActionCable Server") }
  let(:provider) { UNotifier::Provider::ActionCable.new(server) }

  before do
    allow(target).to receive(:login).and_return("login")
    allow(notification).to receive(:target).and_return(target)
    notification_attrs.each { |k, v| allow(notification).to receive(k).and_return(v) }
  end

  it { expect(UNotifier::Provider::ActionCable).to be < UNotifier::Provider::ProviderBase }

  describe "#notify" do
    context "when user is online" do
      before do
        allow(target).to receive(:online?).and_return(true)
      end

      it "should broadcast notification" do
        expect(server).to receive(:broadcast).with(provider.channel_name.call(notification), kind_of(Hash)).once
        provider.notify(notification)
      end
    end

    context "when user is not online" do
      before do
        allow(target).to receive(:online?).and_return(false)
      end

      it "should not broadcast notification" do
        expect(server).not_to receive(:broadcast)
        provider.notify(notification)
      end
    end
  end

  describe "#serialize_notification" do
    it "should return hash with notification attributes" do
      expect(provider.serialize_notification(notification)).to include(notification_attrs)
    end
  end
end

