require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'yaml'

describe "EuCentralBank" do
  before(:each) do
    @bank = EuCentralBank.new
    @dir_path = File.dirname(__FILE__)
    @cache_path = File.expand_path(@dir_path + '/exchange_rates.xml')
    @history_cache_path = File.expand_path(@dir_path + '/exchange_rates_90_day.xml')
    @tmp_cache_path = File.expand_path(@dir_path + '/tmp/exchange_rates.xml')
    @tmp_history_cache_path = File.expand_path(@dir_path + '/tmp/exchange_rates_90_day.xml')
    yml_cache_path = File.expand_path(@dir_path + '/exchange_rates.yml')
    @exchange_rates = YAML.load_file(yml_cache_path)
  end

  after(:each) do
    [@tmp_cache_path, @tmp_history_cache_path].each do |file_name|
      if File.exist? file_name
        File.delete file_name
      end
    end
  end

  it "should save the xml file from ecb given a file path" do
    @bank.save_rates(@tmp_cache_path)
    expect(File.exist?(@tmp_cache_path)).to eq(true)
  end

  it "should save the xml file from ecb given a file path and url" do
    @bank.save_rates(@tmp_history_cache_path, EuCentralBank::ECB_90_DAY_URL)
    expect(File.exist?(@tmp_history_cache_path)).to eq(true)
  end

  it "should raise an error if an invalid path is given to save_rates" do
    expect { @bank.save_rates(nil) }.to raise_exception(InvalidCache)
  end

  it "should update itself with exchange rates from ecb website" do
    allow(OpenURI::OpenRead).to receive(:open).with(EuCentralBank::ECB_RATES_URL) {@cache_path}
    @bank.update_rates
    EuCentralBank::CURRENCIES.each do |currency|
      expect(@bank.get_rate("EUR", currency)).to be > 0
    end
  end

  it "should update itself with exchange rates from ecb website when the data get from cache is illegal" do
    illegal_cache_path = File.expand_path(@dir_path + '/illegal_exchange_rates.xml')
    allow(OpenURI::OpenRead).to receive(:open).with(EuCentralBank::ECB_RATES_URL) {@cache_path}
    @bank.update_rates(illegal_cache_path)
    EuCentralBank::CURRENCIES.each do |currency|
      expect(@bank.get_rate("EUR", currency)).to be > 0
    end
  end

  it "should update itself with exchange rates from cache" do
    @bank.update_rates(@cache_path)
    EuCentralBank::CURRENCIES.each do |currency|
      expect(@bank.get_rate("EUR", currency)).to be > 0
    end
  end

  it "should export to a string a valid cache that can be reread" do
    allow(OpenURI::OpenRead).to receive(:open).with(EuCentralBank::ECB_RATES_URL) {@cache_path}
    s = @bank.save_rates_to_s
    @bank.update_rates_from_s(s)
    EuCentralBank::CURRENCIES.each do |currency|
      expect(@bank.get_rate("EUR", currency)).to be > 0
    end
  end

  it 'should set last_updated when the rates are downloaded' do
    lu1 = @bank.last_updated
    @bank.update_rates(@cache_path)
    lu2 = @bank.last_updated
    sleep(0.01)
    @bank.update_rates(@cache_path)
    lu3 = @bank.last_updated

    expect(lu1).not_to eq(lu2)
    expect(lu2).not_to eq(lu3)
  end

  it 'should set rates_updated_at when the rates are downloaded' do
    lu1 = @bank.rates_updated_at
    @bank.update_rates(@cache_path)
    lu2 = @bank.rates_updated_at

    expect(lu1).not_to eq(lu2)
  end

  it 'should set historical last_updated when the rates are downloaded' do
    lu1 = @bank.historical_last_updated
    @bank.update_historical_rates(@history_cache_path)
    lu2 = @bank.historical_last_updated
    @bank.update_historical_rates(@history_cache_path)
    lu3 = @bank.historical_last_updated

    expect(lu1).not_to eq(lu2)
    expect(lu2).not_to eq(lu3)
  end

  it 'should set rates_updated_at when the rates are downloaded' do
    lu1 = @bank.historical_rates_updated_at
    @bank.update_historical_rates(@history_cache_path)
    lu2 = @bank.historical_rates_updated_at

    expect(lu1).not_to eq(lu2)
  end

  it "should return the correct exchange rates using exchange" do
    @bank.update_rates(@cache_path)
    EuCentralBank::CURRENCIES.each do |currency|
      subunit_to_unit  = Money::Currency.wrap(currency).subunit_to_unit
      exchanged_amount = @bank.exchange(100, "EUR", currency)
      expect(exchanged_amount.cents).to eq((@exchange_rates["currencies"][currency] * subunit_to_unit).round(0).to_i)
    end
  end

  describe '#exchange_with' do
    let(:money) { Money.new(100, 'EUR') }

    it 'should return the correct exchange rates using exchange_with' do
      @bank.update_rates(@cache_path)
      EuCentralBank::CURRENCIES.each do |currency|
        subunit_to_unit  = Money::Currency.wrap(currency).subunit_to_unit
        amount_from_rate = (@exchange_rates["currencies"][currency] * subunit_to_unit).round(0).to_i

        expect(@bank.exchange_with(Money.new(100, "EUR"), currency).cents).to eq(amount_from_rate)
      end
    end

    it 'raises Money::Bank::UnknownRate if rates are not available' do
      expect do
        @bank.exchange_with(money, 'USD')
      end.to raise_error(Money::Bank::UnknownRate, "No conversion rate known for 'EUR' -> 'USD'")
    end

    it 'raises Money::Bank::UnknownRate if rates for a specific date are not available' do
      ['2017-02-22', Date.new(2017, 2, 22)].each do |date|
        expect do
          @bank.exchange_with(money, 'USD', date)
        end.to raise_error(Money::Bank::UnknownRate, "No conversion rate known for 'EUR' -> 'USD' on 2017-02-22")
      end
    end
  end


  it "should return the correct exchange rates using historical exchange" do
    yml_path = File.expand_path(File.dirname(__FILE__) + '/historical_exchange_rates.yml')
    historical_exchange_rates = YAML.load_file(yml_path)
    @bank.update_historical_rates(@history_cache_path)

    EuCentralBank::CURRENCIES.each do |currency|
      subunit_to_unit  = Money::Currency.wrap(currency).subunit_to_unit
      exchanged_amount = @bank.exchange(100, "EUR", currency, "2018-05-11")
      expect(exchanged_amount.cents).to eq((historical_exchange_rates["currencies"][currency] * subunit_to_unit).round(0).to_i)
    end
  end

  it "should update update_rates atomically" do
    even_rates = File.expand_path(File.dirname(__FILE__) + '/even_exchange_rates.xml')
    odd_rates = File.expand_path(File.dirname(__FILE__) + '/odd_exchange_rates.xml')

    odd_thread = Thread.new do
      while true; @bank.update_rates(odd_rates); end
    end

    even_thread = Thread.new do
      while true;  @bank.update_rates(even_rates); end
    end

    # Updating bank rates so that we're sure the test won't fail prematurely
    # (i.e. even without odd_thread/even_thread getting a change to run)
    @bank.update_rates(odd_rates)

    10.times do
      rates = YAML.load(@bank.export_rates(:yaml))
      rates.delete('EUR_TO_EUR')
      rates = rates.values.collect(&:to_i)
      expect(rates.length).to eq(34)
      expect(rates).to satisfy { |rts|
        rts.all?(&:even?) or rts.all?(&:odd?)
      }
    end
    even_thread.kill
    odd_thread.kill
  end

  describe 'export / import rates' do
    let(:other_bank) { EuCentralBank.new }

    before { @bank.update_rates(@cache_path) }

    it 're-imports JSON' do
      raw_rates = @bank.export_rates(:json)
      other_bank.import_rates(:json, raw_rates)

      expect(@bank.store.send(:index)).to eq(other_bank.store.send(:index))
    end

    it 're-imports Marshalled ruby' do
      raw_rates = @bank.export_rates(:ruby)
      other_bank.import_rates(:ruby, raw_rates)

      expect(@bank.store.send(:index)).to eq(other_bank.store.send(:index))
    end

    it 're-imports YAML' do
      raw_rates = @bank.export_rates(:yaml)
      other_bank.import_rates(:yaml, raw_rates)

      expect(@bank.store.send(:index)).to eq(other_bank.store.send(:index))
    end
  end


  it "should exchange money atomically" do
    # NOTE: We need to introduce an artificial delay in the core get_rate
    # function, otherwise it will take a lot of iterations to hit some sort or
    # 'race-condition'
    Money::Bank::VariableExchange.class_eval do
      alias_method :get_rate_original, :get_rate
      def get_rate(*args)
        sleep(Random.rand)
        get_rate_original(*args)
      end
    end
    even_rates = File.expand_path(File.dirname(__FILE__) + '/even_exchange_rates.xml')
    odd_rates = File.expand_path(File.dirname(__FILE__) + '/odd_exchange_rates.xml')

    odd_thread = Thread.new do
      while true; @bank.update_rates(odd_rates); end
    end

    even_thread = Thread.new do
      while true;  @bank.update_rates(even_rates); end
    end

    # Updating bank rates so that we're sure the test won't fail prematurely
    # (i.e. even without odd_thread/even_thread getting a change to run)
    @bank.update_rates(odd_rates)

    10.times do
      expect(@bank.exchange(100, 'INR', 'INR').fractional).to eq(100)
    end
    even_thread.kill
    odd_thread.kill
  end

  it "should raise an error when currency is not available in currency list" do
    expect { @bank.get_rate(EuCentralBank::CURRENCIES.first,"CLP")}.to raise_exception(CurrencyUnavailable)
    expect { @bank.get_rate("CLP",EuCentralBank::CURRENCIES.first)}.to raise_exception(CurrencyUnavailable)
    expect { @bank.get_rate("ARG","CLP")}.to raise_exception(CurrencyUnavailable)
    expect { @bank.get_rate("CLP","ARG")}.to raise_exception(CurrencyUnavailable)
  end

  it "should return 1 for equivilent rates" do
    expect(@bank.get_rate('EUR', 'EUR')).to eq(1)
    expect(@bank.get_rate('AUD', 'AUD')).to eq(1)
  end

  it "should not fail when calculating rate from historical base rates" do
    @bank.update_historical_rates

    # A very naive way of finding a weekday because exchange rates
    # from EU Central Bank are not available on weekends
    workday = Date.today - 7
    workday -= 1 if workday.saturday?
    workday -= 2 if workday.sunday?

    expect {
      @bank.exchange(100, 'GBP', 'EUR', workday)
    }.not_to raise_error
  end

	it "should accept a different store" do
		store = double
		bank = EuCentralBank.new(store)
    expect(bank.store).to eq store
	end
end
