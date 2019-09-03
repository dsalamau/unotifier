RSpec.describe UNotifier::Settings do
  let(:notifications_path) { File.join(__dir__, "fixtures", "notifications.yml") }
  let(:notifications_fixture) { YAML.load_file(notifications_path) }

  describe "#customizable?" do
    subject { UNotifier::Settings.customizable? config }

    context "when urgency is immediate" do
      let(:config) { notifications_fixture["first_category"]["n_immediate"] }
      it { is_expected.to be_falsy }
    end

    context "when urgency is regular" do
      let(:config) { notifications_fixture["first_category"]["n_regular"] }
      it { is_expected.to be_truthy }
    end

    context "when urgency is optional" do
      let(:config) { notifications_fixture["first_category"]["n_optional"] }
      it { is_expected.to be_truthy }
    end

    context "when urgency is onsite" do
      let(:config) { notifications_fixture["first_category"]["n_onsite"] }
      it { is_expected.to be_falsy }
    end
  end

  describe "#filter_customizable" do
    it "rejects non-customizable notifications" do
      expect(
        UNotifier::Settings.filter_customizable(notifications_fixture)
      ).to eq({
        "first_category" => {
          "n_regular" => "regular",
          "n_optional" => "optional",
        },
        "second_category" => {
          "n_target_dependent" => "regular",
          "n_multiple_locales" => "regular",
        },
      })
    end
  end

  describe "#keys_from" do
    it "maps customizble keys hash to stringified key paths with urgency" do
      expect(UNotifier::Settings.keys_from(notifications_fixture))
        .to eq({
          "first_category.n_regular" => "regular",
          "first_category.n_optional" => "optional",
          "second_category.n_target_dependent" => "regular",
          "second_category.n_multiple_locales" => "regular",
        })
    end
  end

  describe "#grouped_by_urgency_keys_from" do
    it "groups stringified key paths by urgency" do
      expect(UNotifier::Settings.grouped_by_urgency_keys_from(notifications_fixture))
        .to eq({
          "optional" => ["first_category.n_optional"],
          "regular" => [
            "first_category.n_regular",
            "second_category.n_target_dependent",
            "second_category.n_multiple_locales",
          ],
        })
    end
  end
end
