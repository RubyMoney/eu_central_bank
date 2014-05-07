require 'rubygems'
require 'open-uri'
require 'nokogiri'
require 'money'

class InvalidCache < StandardError ; end

class EuCentralBank < Money::Bank::VariableExchange

  attr_accessor :last_updated
  attr_accessor :rates_updated_at

  ECB_URL = 'http://www.ecb.europa.eu/stats/eurofxref/eurofxref-daily.xml'
  ECB_90_DAY_URL = 'http://www.ecb.europa.eu/stats/eurofxref/eurofxref-hist-90d.xml'
  CURRENCIES = %w(USD JPY BGN CZK DKK GBP HUF ILS LTL PLN RON SEK CHF NOK HRK RUB TRY AUD BRL CAD CNY HKD IDR INR KRW MXN MYR NZD PHP SGD THB ZAR)

  def update_rates(cache=nil)
    update_parsed_rates(doc(cache))
  end

  def save_rates(cache)
    raise InvalidCache if !cache
    File.open(cache, "w") do |file|
      io = open(ECB_URL);
      io.each_line {|line| file.puts line}
    end
  end

  def update_rates_from_s(content)
    update_parsed_rates(doc_from_s(content))
  end

  def save_rates_to_s
    open(ECB_URL).read
  end

  def exchange(cents, from_currency, to_currency)
    exchange_with(Money.new(cents, from_currency), to_currency)
  end

  def exchange_with(from, to_currency)
    rate = get_rate(from.currency, to_currency)
    unless rate
      from_base_rate, to_base_rate = nil, nil
      @mutex.synchronize do
        from_base_rate = get_rate("EUR", from.currency, without_mutex: true)
        to_base_rate = get_rate("EUR", to_currency, without_mutex: true)
      end
      rate = to_base_rate / from_base_rate
    end
    to_currency_money = Money::Currency.wrap(to_currency).subunit_to_unit
    from_currency_money = from.currency.subunit_to_unit
    decimal_money = BigDecimal(to_currency_money) / BigDecimal(from_currency_money)
    money = (decimal_money * from.cents * rate).round
    Money.new(money, to_currency)
  end

  protected

  def doc(cache)
    rates_source = !!cache ? cache : ECB_URL
    Nokogiri::XML(open(rates_source)).tap do |doc|
      doc.xpath('gesmes:Envelope/xmlns:Cube/xmlns:Cube//xmlns:Cube')
    end
  rescue Nokogiri::XML::XPath::SyntaxError
    Nokogiri::XML(open(ECB_URL))
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
        set_rate("EUR", currency, rate, :without_mutex => true)
      end
      set_rate("EUR", "EUR", 1, without_mutex: true)
    end

    rates_updated_at = doc.xpath('gesmes:Envelope/xmlns:Cube/xmlns:Cube/@time').first.value
    @rates_updated_at = Time.parse(rates_updated_at)

    @last_updated = Time.now
  end
end
