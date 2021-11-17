require 'open-uri'
require 'nokogiri'
require 'money'
require 'money/rates_store/store_with_historical_data_support'
require 'eu_central_bank/rates_document'

class InvalidCache < StandardError ; end

class CurrencyUnavailable < StandardError; end

class EuCentralBank < Money::Bank::VariableExchange

  attr_accessor :last_updated
  attr_accessor :rates_updated_at
  attr_accessor :historical_last_updated
  attr_accessor :historical_rates_updated_at

  SERIALIZER_DATE_SEPARATOR = '_AT_'
  DECIMAL_PRECISION = 5
  CURRENCIES = %w(USD JPY BGN CZK DKK GBP HUF ILS ISK PLN RON SEK CHF NOK HRK RUB TRY AUD BRL CAD CNY HKD IDR INR KRW MXN MYR NZD PHP SGD THB ZAR).map(&:freeze).freeze
  ECB_RATES_URL = 'https://www.ecb.europa.eu/stats/eurofxref/eurofxref-daily.xml'.freeze
  ECB_90_DAY_URL = 'https://www.ecb.europa.eu/stats/eurofxref/eurofxref-hist-90d.xml'.freeze
  ECB_ALL_HIST_URL = 'https://www.ecb.europa.eu/stats/eurofxref/eurofxref-hist.xml'.freeze

  LEGACY_CURRENCIES = %w(CYP SIT ROL TRL)

  def initialize(st = Money::RatesStore::StoreWithHistoricalDataSupport.new, &block)
    super
    @currency_string = nil
  end

  def update_rates(cache=nil, url=ECB_RATES_URL)
    update_parsed_rates(doc(cache, url))
  end

  def update_historical_rates(cache=nil, all=false)
    url = all ? ECB_ALL_HIST_URL : ECB_90_DAY_URL
    update_parsed_historical_rates(doc(cache, url))
  end

  def save_rates(cache, url=ECB_RATES_URL)
    raise InvalidCache unless cache
    File.open(cache, "w") do |file|
      io = open_url(url)
      io.each_line { |line| file.puts line }
    end
  end

  def save_historical_rates(cache, all=false)
    url = all ? ECB_ALL_HIST_URL : ECB_90_DAY_URL
    save_rates(cache, url)
  end

  def update_rates_from_s(content)
    update_parsed_rates(parse_rates(content))
  end

  def save_rates_to_s(url=ECB_RATES_URL)
    open_url(url).read
  end

  def exchange(cents, from_currency, to_currency, date=nil)
    exchange_with(Money.new(cents, from_currency), to_currency, date)
  end

  def exchange_with(from, to_currency, date=nil)
    from_base_rate, to_base_rate = nil, nil
    rate = get_rate(from.currency, to_currency, date)

    unless rate
      store.transaction true do
        from_base_rate = get_rate("EUR", from.currency.to_s, date)
        to_base_rate = get_rate("EUR", to_currency, date)
      end

      unless from_base_rate && to_base_rate
        message = "No conversion rate known for '#{from.currency.iso_code}' -> '#{to_currency}'"
        message << " on #{date.to_s}" if date

        raise Money::Bank::UnknownRate, message
      end

      rate = to_base_rate / from_base_rate
    end

    calculate_exchange(from, to_currency, rate)
  end

  def get_rate(from, to, date = nil)
    return 1 if from == to

    check_currency_available(from)
    check_currency_available(to)

    if date.is_a?(Hash)
      # Backwards compatibility for the opts hash
      date = date[:date]
    end

    store.get_rate(::Money::Currency.wrap(from).iso_code, ::Money::Currency.wrap(to).iso_code, date)
  end

  def set_rate(from, to, rate, date = nil)
    if date.is_a?(Hash)
      # Backwards compatibility for the opts hash
      date = date[:date]
    end
    store.add_rate(::Money::Currency.wrap(from).iso_code, ::Money::Currency.wrap(to).iso_code, rate, date)
  end

  def rates
    store.each_rate.each_with_object({}) do |(from,to,rate,date),hash|
      key = [from, to].join(SERIALIZER_SEPARATOR)
      key = [key, date.to_s].join(SERIALIZER_DATE_SEPARATOR) if date
      hash[key] = rate
    end
  end

  def export_rates(format, file = nil, opts = {})
    raise Money::Bank::UnknownRateFormat unless
      RATE_FORMATS.include? format

    store.transaction true do
      s = case format
      when :json
        JSON.dump(rates)
      when :ruby
        Marshal.dump(rates)
      when :yaml
        YAML.dump(rates)
      end

      unless file.nil?
        File.open(file, "w") {|f| f.write(s) }
      end

      s
    end
  end

  def import_rates(format, s, opts = {})
    raise Money::Bank::UnknownRateFormat unless
      RATE_FORMATS.include? format

    store.transaction true do
      data = case format
       when :json
         JSON.load(s)
       when :ruby
         Marshal.load(s)
       when :yaml
         YAML.load(s)
       end

      data.each do |key, rate|
        from, to = key.split(SERIALIZER_SEPARATOR)
        to, date = to.split(SERIALIZER_DATE_SEPARATOR)

        store.add_rate from, to, BigDecimal(rate, DECIMAL_PRECISION), date
      end
    end

    self
  end

  def check_currency_available(currency)
    currency_string = currency.to_s
    return true if currency_string == "EUR"
    return true if CURRENCIES.include?(currency_string)
    raise CurrencyUnavailable, "No rates available for #{currency_string}"
  end

  protected

  def doc(cache, url=ECB_RATES_URL)
    rates_source = !!cache ? cache : url
    begin
      parse_rates(open_url(rates_source))
    rescue Nokogiri::XML::XPath::SyntaxError
      parse_rates(open_url(url))
    end
  end

  def parse_rates(io)
    doc = ::EuCentralBank::RatesDocument.new
    parser = Nokogiri::XML::SAX::Parser.new(doc)
    parser.parse(io)

    unless doc.errors.empty?
      # Temporary workaround for jruby until
      # https://github.com/sparklemotion/nokogiri/pull/1872 gets
      # released and we bump nokogiri version to include it.
      # TLDR: jruby version of SAX parser will mask all the exceptions
      # raised in document so we will raise it here if there were errors.
      raise Nokogiri::XML::XPath::SyntaxError, doc.errors.join("\n")
    end

    doc
  end

  def copy_rates(rates_document, with_date = false)
    rates_document.rates.each do |date, rates|
      rates.each do |currency, rate|
        next if LEGACY_CURRENCIES.include?(currency)
        set_rate('EUR', currency, BigDecimal(rate, DECIMAL_PRECISION), with_date ? date : nil)
      end
      set_rate('EUR', 'EUR', 1, with_date ? date : nil)
    end
  end

  def update_parsed_rates(rates_document)
    store.transaction true do
      copy_rates(rates_document)
    end
    @rates_updated_at = rates_document.updated_at
    @last_updated = Time.now
  end

  def update_parsed_historical_rates(rates_document)
    store.transaction true do
      copy_rates(rates_document, true)
    end
    @historical_rates_updated_at = rates_document.updated_at
    @historical_last_updated = Time.now
  end

  private

  def calculate_exchange(from, to_currency, rate)
    to_currency_money = Money::Currency.wrap(to_currency).subunit_to_unit
    from_currency_money = from.currency.subunit_to_unit
    decimal_money = BigDecimal(to_currency_money, DECIMAL_PRECISION) / BigDecimal(from_currency_money, DECIMAL_PRECISION)
    money = (decimal_money * from.cents * rate).round
    Money.new(money, to_currency)
  end

  def open_url(url)
    if RUBY_VERSION >= '2.5.0'
      URI.open(url)
    else
      open(url)
    end
  end
end
