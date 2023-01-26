require 'eu_central_bank'
require 'yaml'

I18n.enforce_available_locales = false

def load_exchange_rates_from_file(file)
  load_exchange_rates(File.open(file))
end

def load_exchange_rates(input)
  if Gem::Version.new(Psych::VERSION) >= Gem::Version.new('3.1.0')
    ::YAML.safe_load(input, permitted_classes: [ BigDecimal ])
  else
    ::YAML.safe_load(input, [ BigDecimal ], [], true)
  end
end