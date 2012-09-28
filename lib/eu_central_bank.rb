require 'rubygems'
require 'open-uri'
require 'nokogiri'
require 'money'
require 'redis'

class InvalidCache < StandardError
  def message
    "You must either set the redis url via instance.redis = 'redis://server:port' or set a cache file location via instance.cache = /path/to/file "
  end
end

class EuCentralBank < Money::Bank::VariableExchange

  attr_accessor :last_updated

  ECB_RATES_URL = 'http://www.ecb.int/stats/eurofxref/eurofxref-daily.xml'
  CURRENCIES = %w(USD JPY BGN CZK DKK GBP HUF LTL LVL PLN RON SEK CHF NOK HRK RUB TRY AUD BRL CAD CNY HKD IDR INR KRW MXN MYR NZD PHP SGD THB ZAR)

  def redis=(server)
    url = server
    @redis = Redis.connect(url: url, thread_safe: true)
  end

  def redis
    return @redis if @redis
    raise InvalidCache
  end

  def cache=(file=nil)
    @cache = file
  end

  def cache
    return @cache if @cache
    raise InvalidCache
  end

  def save_rates
    raise InvalidCache if not redis and not cache
    io = open(ECB_RATES_URL) 
    if redis
      redis.set('eu_central_bank', io.read)
    elsif cache
      File.open(cache, "w") do |file|
        io.each_line {|line| file.puts line}
      end
    end
  end

  def load_rates
    if redis 
      redis.get('eu_central_bank')
      update_parsed_rates(exchange_rates(redis.get('eu_central_bank')))
    else
      update_parsed_rates(exchange_rates(cache))
    end
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
