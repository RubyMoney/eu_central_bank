require 'rubygems'
require 'open-uri'
require 'nokogiri'
require 'money'

class InvalidCache < StandardError ; end

class EuCentralBank < Money::Bank::VariableExchange

  attr_accessor :last_updated
  attr_accessor :rates_updated_at

  ECB_RATES_URL = 'http://www.ecb.europa.eu/stats/eurofxref/eurofxref-daily.xml'
  CURRENCIES = %w(USD JPY BGN CZK DKK GBP HUF ILS LTL PLN RON SEK CHF NOK HRK RUB TRY AUD BRL CAD CNY HKD IDR INR KRW MXN MYR NZD PHP SGD THB ZAR)

  def update_rates(cache=nil)
    update_parsed_rates(doc(cache))
  end

  def save_rates(cache)
    raise InvalidCache if !cache
    File.open(cache, "w") do |file|
      io = open(ECB_RATES_URL) ;
      io.each_line {|line| file.puts line}
    end
  end

  def update_rates_from_s(content)
    update_parsed_rates(doc_from_s(content))
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

  def doc(cache)
    rates_source = !!cache ? cache : ECB_RATES_URL
    Nokogiri::XML(open(rates_source)).tap {|doc| doc.xpath('gesmes:Envelope/xmlns:Cube/xmlns:Cube//xmlns:Cube') }
  rescue Nokogiri::XML::XPath::SyntaxError
    Nokogiri::XML(open(ECB_RATES_URL))
  end

  def doc_from_s(content)
    Nokogiri::XML(content)
  end

  # NOTE: We are creating a temporary bank object, adding rates to it one-by-
  # one and then using it to replace the rates on `self` using import_rates.
  # We need to do this because import_rates holds a lock on @mutex while ALL
  # rates are being updated. This ensures that rate updation is always atomic
  # in nature -- at no point in time will some other thread see an
  # inconsistent view of the rates, i.e. few rates from this update & few
  # rates from the previous update.
  def update_parsed_rates(doc)
    rates = doc.xpath('gesmes:Envelope/xmlns:Cube/xmlns:Cube//xmlns:Cube')

    temp_bank = self.class.new

    rates.each do |exchange_rate|
      rate = exchange_rate.attribute("rate").value.to_f
      currency = exchange_rate.attribute("currency").value
      temp_bank.add_rate("EUR", currency, rate)
    end
    temp_bank.add_rate("EUR", "EUR", 1)

    import_rates(:yaml, temp_bank.export_rates(:yaml))

    rates_updated_at = doc.xpath('gesmes:Envelope/xmlns:Cube/xmlns:Cube/@time').first.value
    @rates_updated_at = Time.parse(rates_updated_at)

    @last_updated = Time.now
  end
end
