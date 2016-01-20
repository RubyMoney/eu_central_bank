module Money::RatesStore
  module EuCentralBankHistoricalDataSupport

    def add_rate(currency_iso_from, currency_iso_to, rate, date = nil)
      transaction { index[rate_key_for(currency_iso_from, currency_iso_to, date)] = rate }
    end

    def get_rate(currency_iso_from, currency_iso_to, date = nil)
      transaction { index[rate_key_for(currency_iso_from, currency_iso_to, date)] }
    end

    private

      def rate_key_for(currency_iso_from, currency_iso_to, date = nil)
        key = [currency_iso_from, currency_iso_to].join(Memory::INDEX_KEY_SEPARATOR)
        key << "_#{date.to_s}" if date
        key.upcase
      end

  end
end