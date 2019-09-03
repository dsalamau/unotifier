module UNotifier
  class Settings
    DEFAULT_URGENCY = "external"

    def self.customizable?(config)
      %w(regular optional).include?(config["urgency"])
    end

    def self.filter_customizable(config)
      config.map do |key, subkeys|
        filtered = subkeys.select do |subkey, value|
          (value.has_key?("urgency") && customizable?(value)) ||
          (value.has_key?("target") && value["target"].values.any? { |subvalue| customizable?(subvalue) })
        end

        filtered = filtered.each_with_object({}) do |(subkey, value), out|
          out[subkey] = value["urgency"] ||
                        value["target"]
                          .select { |_, subvalue| customizable?(subvalue) }
                          .map { |_, subvalue| subvalue["urgency"] }
                          .first
        end

        [key, filtered]
      end.to_h.select { |_, subkeys| !subkeys.empty?  }
    end

    def self.keys_from(config)
      flatten_keys filter_customizable(config)
    end

    def self.grouped_by_urgency_keys_from(config)
      keys_from(config).each_with_object({}) do |(key, urgency), out|
        out[urgency] ||= []
        out[urgency] << key
      end
    end

    private

    def self.flatten_keys(keys)
      keys.map do |key, subkeys|
        subkeys.map do |subkey, urgency|
          { "#{key}.#{subkey}" => urgency }
        end
      end.flatten.reduce({}, :merge)
    end
  end
end
