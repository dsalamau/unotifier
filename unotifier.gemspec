
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "unotifier/version"

Gem::Specification.new do |spec|
  spec.name          = "unotifier"
  spec.version       = UNotifier::VERSION
  spec.authors       = ["mgpnd"]
  spec.email         = ["stillintop@gmail.com"]

  spec.summary       = "Ultimate user notification tool for web apps"
  spec.homepage      = "https://gitlab.com/hodlhodl-public/unotifier"
  spec.license       = "MIT"

  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "https://rubygems.org"

    spec.metadata["homepage_uri"] = spec.homepage
    spec.metadata["sourc_code_uri"] = "https://gitlab.com/hodlhodl-public/unotifier"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) || f.match(%r{^\.rspec}) }
  end

  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.17"
  spec.add_development_dependency "byebug"
  spec.add_development_dependency "i18n"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
