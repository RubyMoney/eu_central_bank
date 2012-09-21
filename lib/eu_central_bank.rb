require 'rubygems'
require 'open-uri'
require 'nokogiri'
require 'money'
require 'redis'

class InvalidCache < StandardError ; end

class EuCentralBank < Money::Bank::VariableExchange

  attr_accessor :last_updated

  ECB_RATES_URL = 'http://www.ecb.int/stats/eurofxref/eurofxref-daily.xml'
  CURRENCIES = %w(USD JPY BGN CZK DKK GBP HUF LTL LVL PLN RON SEK CHF NOK HRK RUB TRY AUD BRL CAD CNY HKD IDR INR KRW MXN MYR NZD PHP SGD THB ZAR)

  def initialize
    @url = ENV['REDIS_URL'] || "redis://localhost:6379"
    @redis = Redis.connect(url: @url, thread_safe: true)
    super
  end

  def save_rates
    raise InvalidCache if !@redis
    io = open(ECB_RATES_URL) 
    @redis.set('eu_central_bank', io.read)
  end

  def load_rates
    @redis.get('eu_central_bank')
    update_parsed_rates(exchange_rates(@redis.get('eu_central_bank')))
  end

  def update_rates_from_s(content)
    update_parsed_rates(exchange_rates_from_s(content))
  end

  def save_rates_to_s
    open(ECB_RATES_URL).read
  end

  def exchange(cents, from_currency, to_currency)
    exchange_with(Money.new(cents, from_currency), to_currency)
  end

  def exchange_with(from, to_currency)
    rate = get_rate(from.currency, to_currency)
    unless rate
      from_base_rate = get_rate("EUR", from.currency)
      to_base_rate = get_rate("EUR", to_currency)
      rate = to_base_rate / from_base_rate
    end
    Money.new(((Money::Currency.wrap(to_currency).subunit_to_unit.to_f / from.currency.subunit_to_unit.to_f) * from.cents * rate).round, to_currency)
  end

  protected

  def exchange_rates(cache=nil)
    rates_source = !!cache ? cache : open(ECB_RATES_URL)
    doc = Nokogiri::XML(rates_source)
    doc.xpath('gesmes:Envelope/xmlns:Cube/xmlns:Cube//xmlns:Cube')
  end

  def exchange_rates_from_s(content)
    doc = Nokogiri::XML(content)
    doc.xpath('gesmes:Envelope/xmlns:Cube/xmlns:Cube//xmlns:Cube')
  end

  def update_parsed_rates(rates)
    rates.each do |exchange_rate|
      rate = exchange_rate.attribute("rate").value.to_f
      currency = exchange_rate.attribute("currency").value
      add_rate("EUR", currency, rate)
    end
    add_rate("EUR", "EUR", 1)
    @last_updated = Time.now
  end
end
