require "i18n"


RSpec.describe UNotifier do
  it "has a version number" do
    expect(UNotifier::VERSION).not_to be nil
  end

  let(:action_cable_server) { double("ActionCable Server") }
  let(:site_provider) { double("Site Provider")}

  let(:notification_mailer) { double("Notification Mailer") }
  let(:notification_email) { double("Notification Email") }
  let(:external_provider) { double("External Provider") }

  let(:target) { double("Target") }
  let(:resource_class) { double("Resource Class") }
  let(:notification_entity) { double("Notification Entity") }
  let(:notifications_path) { File.join(__dir__, "fixtures", "notifications.yml") }

  let(:notifications_fixture) { YAML.load_file(notifications_path) }

  before do
    class ExternalNotificationProvider;end
    allow(external_provider).to receive(:class).and_return(ExternalNotificationProvider)

    UNotifier.reload!
    UNotifier.configure do |config|
      config.site_providers = [site_provider]
      config.external_providers = [external_provider]
      config.resource_class = resource_class
      config.notifications_path = notifications_path
      config.localization_provider = I18n
    end
  end

  describe "#notifications_config" do
    context "when config file exists" do
      it "reads notifications hash from provided config file" do
        expect(UNotifier.notifications_config).to eq(notifications_fixture)
      end
    end

    context "when config file doesn't exist" do
      let(:notifications_path) { "nonexistent_file" }

      it "raises NotificationsConfigNotFoundError" do
        expect { UNotifier.notifications_config }
          .to raise_error(UNotifier::NotificationsConfigNotFoundError)
      end
    end
  end

  describe "#load_notification" do
    subject { UNotifier.load_notification(key) }

    context "when notification key exists" do
      let(:key) { "first_category.n_regular" }

      it { is_expected.to eq(
        notifications_fixture["first_category"]["n_regular"]
      ) }
    end

    context "when notification key doesn't exist" do
      let(:key) { "something_nonexistent" }

      it { is_expected.to be_nil }
    end
  end

  describe "#load_notification!" do
    context "when notification key doesn't exist" do
      it "raises NotificationNotFoundError" do
        expect { UNotifier.load_notification!("nonexistent") }
          .to raise_error(UNotifier::NotificationNotFoundError)
      end
    end
  end

  describe "#urgency_for" do
    context "when notification key exists" do
      context "when notification spec has only one urgency option" do
        it "returns urgency for provided notification key" do
          expect(
            UNotifier.urgency_for("first_category.n_regular")
           ).to eq(
              notifications_fixture["first_category"]["n_regular"]["urgency"]
            )
        end
      end

      context "when notification urgency depends on target" do
        context "when targe is defined in config" do
          it "return urgency based on target" do
            expect(
              UNotifier.urgency_for("second_category.n_target_dependent", target: "user")
            ).to eq(
              notifications_fixture["second_category"]["n_target_dependent"]["target"]["user"]["urgency"]
            )
            expect(
              UNotifier.urgency_for("second_category.n_target_dependent", target: "admin")
            ).to eq(
              notifications_fixture["second_category"]["n_target_dependent"]["target"]["admin"]["urgency"]
            )
          end
        end

        context "when target is not defined in config" do
          it "raises UnknownTargetError" do
            expect {
              UNotifier.urgency_for("second_category.n_target_dependent", target: "unknown")
            }.to raise_error(UNotifier::UnknownTargetError)
          end
        end
      end
    end

    context "when notification key doesn't exist" do
      it "raises NotificationNotFoundError" do
        expect { UNotifier.urgency_for("nonexistent") }
          .to raise_error(UNotifier::NotificationNotFoundError)
      end
    end
  end

  describe "#locale_key_for" do
    context "when notification key exists" do
      context "when config doesn't have locale_options" do
        it "returns locale_key composed from notification key name" do
          expect(UNotifier.locale_key_for("first_category.n_regular"))
            .to eq("notifications.first_category.n_regular")
        end
      end

      context "when config has locale_options" do
        context "when parameters have :locale_key attribute" do
          context "when :locale_key has matching option" do
            it "returns locale key for provided parameter" do
              expect(
                UNotifier.locale_key_for("second_category.n_multiple_locales",
                                        locale_key: "on_page")
              ).to eq("notifications.second_category.n_multiple_locales.on_page")
            end
          end

          context "when :locale_key doesn't have matching option" do
            it "raises UnknownLocaleKeyError" do
              expect {
                UNotifier.locale_key_for("second_category.n_multiple_locales",
                                        locale_key: "nonexistent")
              }.to raise_error(UNotifier::UnknownLocaleKeyError)
            end
          end
        end

        context "when there's no :locale_key in parameters" do
          it "raises EmptyLocaleKeyError" do
            expect { UNotifier.locale_key_for("second_category.n_multiple_locales") }
              .to raise_error(UNotifier::EmptyLocaleKeyError)
          end
        end
      end
    end

    context "when notification key doesn't exist" do
      it "raises NotificationNotFoundError" do
        expect { UNotifier.locale_key_for("nonexistent") }
          .to raise_error(UNotifier::NotificationNotFoundError)
      end
    end
  end

  describe "#notify" do
    let(:key) { "first_category.n_regular" }
    let(:params) { Hash.new }
    let(:user_settings) { "external" }

    before do
      allow(I18n).to receive(:t).and_return("")
      allow(target).to receive(:online?).and_return(true)
      allow(target).to receive(:locale).and_return(:en)
      allow(target).to receive(:notification_settings).and_return({ key => user_settings })
      allow(notification_entity).to receive(:urgency).and_return(notifications_fixture.dig(*key.split("."), "urgency"))
      allow(notification_entity).to receive(:target).and_return(target)
      allow(notification_entity).to receive(:save!)
      allow(resource_class).to receive(:new).and_return(notification_entity)
      allow(site_provider).to receive(:notify)
      allow(external_provider).to receive(:notify)
    end

    it "creates notification entity" do
      expect(notification_entity).to receive(:save!)
      expect(resource_class).to receive(:new).and_return(notification_entity)
      UNotifier.notify(key, target)
    end

    it "passes locale params to I18n" do
      locale_key = UNotifier.locale_key_for(key)
      params = { first: "first", second: "second" }
      expect(I18n).to receive(:t).with(/#{locale_key}.(body|title)/, hash_including(params))
      UNotifier.notify(key, target, params)
    end

    it "correctly chooses localization key for various notification providers or defaults to a default one if no key for the provider exists" do
      locale_key = UNotifier.locale_key_for("first_category.n_immediate")
      params = { first: "first", second: "second" }
      allow(notification_entity).to receive(:urgency).and_return("immediate")
      allow(notification_entity).to receive(:title=)
      allow(notification_entity).to receive(:body=)
      expect(I18n).to receive(:t).with(/#{locale_key}\.(body|title)/, hash_including(params))
      expect(I18n).to receive(:t).with(/#{locale_key}\.ExternalNotificationProvider\.(body|title)/, hash_including(params)).and_return("Title Or Body")
      expect(I18n).to receive(:exists?).with(/#{locale_key}\.Double\.(body|title)/).and_return(false).twice
      expect(I18n).to receive(:exists?).with(/#{locale_key}\.ExternalNotificationProvider\.(body|title)/).and_return(true).twice
      UNotifier.notify("first_category.n_immediate", target, params)
    end

    subject { -> { UNotifier.notify(key, target, params) } }

    context "when :onsite_only parameter passed" do
      let(:key) { "first_category.n_immediate" }
      let(:params) { { onsite_only: true } }

      it { is_expected.to notify_with([site_provider]) }
      it { is_expected.not_to notify_with([external_provider]) }
    end

    context "when :external_only parameter passed" do
      let(:key) { "first_category.n_immediate" }
      let(:params) { { external_only: true } }

      it { is_expected.to notify_with([external_provider]) }
      it { is_expected.not_to notify_with([site_provider]) }
    end

    context "when target is online" do
      context "when notification urgency is 'immediate'" do
        let(:key) { "first_category.n_immediate" }

        %w(off onsite external unknown).each do |level|
          context "when user has '#{level}' setting value for the key" do
            let(:user_settings) { level }

            it { is_expected.to notify_with([site_provider, external_provider]) }
          end
        end
      end

      %w(regular onsite).each do |urgency|
        context "when notification urgency is '#{urgency}'" do
          let(:key) { "first_category.n_#{urgency}" }

          %w(off onsite external unknown).each do |level|
            context "when user has '#{level}' setting value for the key" do
              let(:user_settings) { level }

              it { is_expected.to notify_with([site_provider]) }

              it { is_expected.not_to notify_with([external_provider]) }
            end
          end
        end
      end

      context "when notification urgency is 'optional'" do
        let(:key) { "first_category.n_optional" }

        %w(onsite external unknown).each do |level|
          context "when user has '#{level}' setting value for the key" do
            let(:user_settings) { level }

            it { is_expected.to notify_with([site_provider]) }

            it { is_expected.not_to notify_with([external_provider]) }
          end
        end

        context "when user has 'off' setting value for the key" do
          let(:user_settings) { "off" }

          it { is_expected.not_to notify_with([site_provider, external_provider]) }
        end
      end
    end

    context "when target is offline" do
      before do
        allow(target).to receive(:online?).and_return(false)
      end

      context "when notification urgency is 'immediate'" do
        let(:key) { "first_category.n_immediate" }

        %w(off onsite external unknown).each do |level|
          context "when user has '#{level}' setting value for the key" do
            let(:user_settings) { level }

            it { is_expected.to notify_with([external_provider]) }

            it { is_expected.not_to notify_with([site_provider]) }
          end
        end
      end

      %w(regular optional).each do |urgency|
        context "when notificaion urgency is '#{urgency}'" do
          let(:key) { "first_category.n_#{urgency}" }

          context "when user has 'external' setting value for the key" do
            let(:user_settings) { "external" }

            it { is_expected.to notify_with([external_provider]) }

            it { is_expected.not_to notify_with([site_provider]) }
          end

          %w(off onsite unknown).each do |level|
            context "when user has '#{level}' setting value for the key" do
              let(:user_settings) { level }

              it { is_expected.not_to notify_with([site_provider, external_provider]) }
            end
          end
        end
      end

      context "when notifiction urgency is 'onsite'" do
        let(:key) { "first_category.n_onsite" }

        %w(off onsite external unknown).each do |level|
          context "when user has '#{level}' setting value for the key" do
            let(:user_settings) { level }

            it { is_expected.not_to notify_with([site_provider, external_provider])}
          end
        end
      end
    end
  end

  describe "#notification_settings_for" do
    let(:user_settings) { {
      "first_category.n_regular" => "onsite",
      "first_category.n_optional" => "off",
    } }

    before do
      allow(target).to receive(:notification_settings).and_return(user_settings)
    end

    subject { UNotifier.notification_settings_for(target) }

    context "when user have setting value for the key" do
      it "loads value from user's settings" do
        expect(subject["optional"]).to include({ "first_category.n_optional" => "off" })
        expect(subject["regular"]).to include({ "first_category.n_regular" => "onsite" })
      end
    end

    context "when user doesn't have setting value for the key" do
      it "sets '#{UNotifier::Settings::DEFAULT_URGENCY}' value for the key" do
        expect(subject["regular"]).to include({
          "second_category.n_target_dependent" => UNotifier::Settings::DEFAULT_URGENCY
        })
      end
    end
  end
end
