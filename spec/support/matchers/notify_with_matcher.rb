require "rspec/expectations"

RSpec::Matchers.define :notify_with do |providers|
  supports_block_expectations

  match do |action|
    providers.each { |p| expect(p).to receive(:notify) }
    action.call
    true
  end

  match_when_negated do |action|
    providers.each { |p| expect(p).not_to receive(:notify) }
    action.call
    true
  end
end
