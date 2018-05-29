require 'money/rates_store/eu_central_bank_historical_data_support'
module Money::RatesStore
  class StoreWithHistoricalDataSupport < Money::RatesStore::Memory
    include Money::RatesStore::EuCentralBankHistoricalDataSupport
  end
end
