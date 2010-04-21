require 'rubygems'
require 'open-uri'
require 'nokogiri'
require 'money'

class InvalidCache < StandardError ; end

class EuCentralBank < Money::VariableExchangeBank

  ECB_RATES_URL = 'http://www.ecb.int/stats/eurofxref/eurofxref-daily.xml'
  CURRENCIES = %w(USD JPY BGN CZK DKK EEK GBP HUF LTL LVL PLN RON SEK CHF NOK HRK RUB TRY AUD BRL CAD CNY HKD IDR INR KRW MXN MYR NZD PHP SGD THB ZAR)

  def update_rates(cache=nil)
    exchange_rates(cache).each do |exchange_rate|
      rate = exchange_rate.attribute("rate").value.to_f
      currency = exchange_rate.attribute("currency").value
      add_rate("EUR", currency, rate)
    end
    add_rate("EUR", "EUR", 1)
  end

  def save_rates(cache)
    raise InvalidCache if !cache
    File.open(cache, "w") do |file|
      io = open(ECB_RATES_URL) ;
      io.each_line {|line| file.puts line}
    end
  end

  def exchange(cents, from_currency, to_currency)
    rate = get_rate(from_currency, to_currency)
    if !rate
      from_base_rate = get_rate("EUR", from_currency)
      to_base_rate = get_rate("EUR", to_currency)
      rate = to_base_rate / from_base_rate
    end
    (cents * rate).floor
  end

  protected

  def exchange_rates(cache=nil)
    rates_source = !!cache ? cache : ECB_RATES_URL
    doc = Nokogiri::XML(open(rates_source))
    doc.xpath('gesmes:Envelope/xmlns:Cube/xmlns:Cube//xmlns:Cube')
  end

end
