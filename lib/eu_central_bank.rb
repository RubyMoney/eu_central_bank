require 'rubygems'
require 'open-uri'
require 'nokogiri'
require 'money'

class InvalidCache < StandardError ; end

class EuCentralBank < Money::Bank::VariableExchange

  attr_accessor :last_updated, :rates_updated_at
  attr_accessor :historical_last_updated, :historical_rates_updated_at

  ECB_URL = 'http://www.ecb.europa.eu/stats/eurofxref/eurofxref-daily.xml'
  ECB_90_DAY_URL = 'http://www.ecb.europa.eu/stats/eurofxref/eurofxref-hist-90d.xml'
  CURRENCIES = %w(USD JPY BGN CZK DKK GBP HUF ILS LTL PLN RON SEK CHF NOK HRK RUB TRY AUD BRL CAD CNY HKD IDR INR KRW MXN MYR NZD PHP SGD THB ZAR)

  def update_rates(cache=nil)
    update_parsed_rates(doc(cache))
  end

  def update_historical_rates(cache=nil)
    update_parsed_historical_rates(doc(cache, ECB_90_DAY_URL))
  end

  def save_rates(cache, url=ECB_URL)
    raise InvalidCache unless cache
    File.open(cache, "w") do |file|
      io = open(url);
      io.each_line { |line| file.puts line }
    end
  end

  def update_rates_from_s(content)
    update_parsed_rates(doc_from_s(content))
  end

  def save_rates_to_s(url=ECB_URL)
    open(url).read
  end

  def exchange(cents, from_currency, to_currency, date=nil)
    exchange_with(Money.new(cents, from_currency), to_currency, date)
  end

  def exchange_with(from, to_currency, date=nil)
    from_base_rate, to_base_rate = nil, nil

    unless get_rate(from, to_currency, {date: date})
      @mutex.synchronize do
        opts = { date: date, without_mutex: true }
        from_base_rate = get_rate("EUR", from.currency.to_s, opts)
        to_base_rate = get_rate("EUR", to_currency, opts)
      end
      exchange_rate = to_base_rate / from_base_rate
    end

    calculate_exchange(from, to_currency, exchange_rate)
  end

  def get_rate(from, to, opts = {})
    if opts[:date]
      fn = -> { @rates[rate_key_for(from, to, opts[:date])] }
    else
      fn = -> { @rates[rate_key_for(from, to)] }
    end

    if opts[:without_mutex]
      fn.call
    else
      @mutex.synchronize { fn.call }
    end
  end

  def set_rate(from, to, rate, opts = {})
    if opts[:date]
      fn = -> { @rates[rate_key_for(from, to, opts[:date])] = rate }
    else
      fn = -> { @rates[rate_key_for(from, to)] = rate }
    end

    if opts[:without_mutex]
      fn.call
    else
      @mutex.synchronize { fn.call }
    end
  end

  protected

  def doc(cache, url=ECB_URL)
    rates_source = !!cache ? cache : url
    Nokogiri::XML(open(rates_source)).tap do |doc|
      doc.xpath('gesmes:Envelope/xmlns:Cube/xmlns:Cube//xmlns:Cube')
    end
  rescue Nokogiri::XML::XPath::SyntaxError
    Nokogiri::XML(open(url))
  end

  def doc_from_s(content)
    Nokogiri::XML(content)
  end

  def update_parsed_rates(doc)
    rates = doc.xpath('gesmes:Envelope/xmlns:Cube/xmlns:Cube//xmlns:Cube')

    @mutex.synchronize do
      rates.each do |exchange_rate|
        rate = BigDecimal(exchange_rate.attribute("rate").value)
        currency = exchange_rate.attribute("currency").value
        set_rate("EUR", currency, rate, without_mutex: true)
      end
      set_rate("EUR", "EUR", 1, without_mutex: true)
    end

    rates_updated_at = doc.xpath('gesmes:Envelope/xmlns:Cube/xmlns:Cube/@time').first.value
    @rates_updated_at = Time.parse(rates_updated_at)
    @last_updated = Time.now
  end

  def update_parsed_historical_rates(doc)
    rates = doc.xpath('gesmes:Envelope/xmlns:Cube/xmlns:Cube//xmlns:Cube')

    @mutex.synchronize do
      rates.each do |exchange_rate|
        rate = BigDecimal(exchange_rate.attribute("rate").value)
        currency = exchange_rate.attribute("currency").value
        opts = { without_mutex: true }
        opts[:date] = exchange_rate.parent.attribute("time").value
        set_rate("EUR", currency, rate, opts)
        set_rate("EUR", "EUR", 1, opts)
      end
    end

    rates_updated_at = doc.xpath('gesmes:Envelope/xmlns:Cube/xmlns:Cube/@time').first.value
    @historical_rates_updated_at = Time.parse(rates_updated_at)
    @historical_last_updated = Time.now
  end

  private

  def calculate_exchange(from, to_currency, rate)
    to_currency_money = BigDecimal(Money::Currency.wrap(to_currency).subunit_to_unit)
    from_money = BigDecimal(from.currency.subunit_to_unit)
    money_ratio = to_currency_money / from_money
    money = (money_ratio * from.cents * rate).round
    Money.new(money, to_currency)
  end

  def rate_key_for(from, to, date=nil)
    key = "#{from}_TO_#{to}"
    key << "_#{date.to_s}" if date
    key.upcase
  end
end
