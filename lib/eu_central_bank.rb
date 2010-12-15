require 'rubygems'
require 'open-uri'
require 'nokogiri'
gem 'money', '=3.1.5'
require 'money'

class InvalidCache < StandardError ; end

class EuCentralBank < Money::Bank::VariableExchange

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
    warn '[DEPRECIATION] `exchange` will be removed in money v3.2.0 and eu_central_bank v0.2.0, use #exchange_with instead'
    exchange_with(Money.new(cents, from_currency), to_currency)
  end

  def exchange_with(from, to_currency)
    rate = get_rate(from.currency, to_currency)
    unless rate
      from_base_rate = get_rate("EUR", from.currency)
      to_base_rate = get_rate("EUR", to_currency)
      rate = to_base_rate / from_base_rate
    end
    Money.new((from.cents * rate).floor, to_currency)
  end

  protected

  def exchange_rates(cache=nil)
    rates_source = !!cache ? cache : ECB_RATES_URL
    doc = Nokogiri::XML(open(rates_source))
    doc.xpath('gesmes:Envelope/xmlns:Cube/xmlns:Cube//xmlns:Cube')
  end

end
