require 'open-uri'
require 'nokogiri'
require 'money'
require 'money/rates_store/store_with_historical_data_support'

class InvalidCache < StandardError ; end

class CurrencyUnavailable < StandardError; end

class EuCentralBank < Money::Bank::VariableExchange

  attr_accessor :last_updated
  attr_accessor :rates_updated_at
  attr_accessor :historical_last_updated
  attr_accessor :historical_rates_updated_at

  SERIALIZER_DATE_SEPARATOR = '_AT_'

  CURRENCIES = %w(USD JPY BGN CZK DKK GBP HUF ILS ISK PLN RON SEK CHF NOK HRK RUB TRY AUD BRL CAD CNY HKD IDR INR KRW MXN MYR NZD PHP SGD THB ZAR).map(&:freeze).freeze
  ECB_RATES_URL = 'https://www.ecb.europa.eu/stats/eurofxref/eurofxref-daily.xml'.freeze
  ECB_90_DAY_URL = 'https://www.ecb.europa.eu/stats/eurofxref/eurofxref-hist-90d.xml'.freeze

  def initialize(st = Money::RatesStore::StoreWithHistoricalDataSupport.new, &block)
    super
    @currency_string = nil
  end

  def update_rates(cache=nil)
    update_parsed_rates(doc(cache))
  end

  def update_historical_rates(cache=nil)
    update_parsed_historical_rates(doc(cache, ECB_90_DAY_URL))
  end

  def save_rates(cache, url=ECB_RATES_URL)
    raise InvalidCache unless cache
    File.open(cache, "w") do |file|
      io = open(url);
      io.each_line { |line| file.puts line }
    end
  end

  def update_rates_from_s(content)
    update_parsed_rates(doc_from_s(content))
  end

  def save_rates_to_s(url=ECB_RATES_URL)
    open(url).read
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

        store.add_rate from, to, BigDecimal(rate), date
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
    Nokogiri::XML(open(rates_source)).tap { |doc| doc.xpath('gesmes:Envelope/xmlns:Cube/xmlns:Cube//xmlns:Cube') }
  rescue Nokogiri::XML::XPath::SyntaxError
    Nokogiri::XML(open(url))
  end

  def doc_from_s(content)
    Nokogiri::XML(content)
  end

  def update_parsed_rates(doc)
    rates = doc.xpath('gesmes:Envelope/xmlns:Cube/xmlns:Cube//xmlns:Cube')

    store.transaction true do
      rates.each do |exchange_rate|
        rate = BigDecimal(exchange_rate.attribute("rate").value)
        currency = exchange_rate.attribute("currency").value
        set_rate("EUR", currency, rate)
      end
      set_rate("EUR", "EUR", 1)
    end

    rates_updated_at = doc.xpath('gesmes:Envelope/xmlns:Cube/xmlns:Cube/@time').first.value
    @rates_updated_at = Time.parse(rates_updated_at)

    @last_updated = Time.now
  end

  def update_parsed_historical_rates(doc)
    rates = doc.xpath('gesmes:Envelope/xmlns:Cube/xmlns:Cube//xmlns:Cube')

    store.transaction true do
      rates.each do |exchange_rate|
        rate = BigDecimal(exchange_rate.attribute("rate").value)
        currency = exchange_rate.attribute("currency").value
        date = exchange_rate.parent.attribute("time").value
        set_rate("EUR", currency, rate, date)
      end
    end

    rates_updated_at = doc.xpath('gesmes:Envelope/xmlns:Cube/xmlns:Cube/@time').first.value
    @historical_rates_updated_at = Time.parse(rates_updated_at)

    @historical_last_updated = Time.now
  end

  private

  def calculate_exchange(from, to_currency, rate)
    to_currency_money = Money::Currency.wrap(to_currency).subunit_to_unit
    from_currency_money = from.currency.subunit_to_unit
    decimal_money = BigDecimal(to_currency_money) / BigDecimal(from_currency_money)
    money = (decimal_money * from.cents * rate).round
    Money.new(money, to_currency)
  end
end
