module Money::RatesStore
  module EuCentralBankHistoricalDataSupport

    def add_rate(currency_iso_from, currency_iso_to, rate, date = nil)
      transaction { index[rate_key_for(currency_iso_from, currency_iso_to, date)] = rate }
    end

    def get_rate(currency_iso_from, currency_iso_to, date = nil)
      transaction { index[rate_key_for(currency_iso_from, currency_iso_to, date)] }
    end

    # Iterate over rate tuples (iso_from, iso_to, rate)
    #
    # @yieldparam iso_from [String] Currency ISO string.
    # @yieldparam iso_to [String] Currency ISO string.
    # @yieldparam rate [Numeric] Exchange rate.
    # @yieldparam date [Date] Historical date for the exchange rate. Nil if the rate is not historical rate.
    #
    # @return [Enumerator]
    #
    # @example
    #   store.each_rate do |iso_from, iso_to, rate|
    #     puts [iso_from, iso_to, rate].join
    #   end
    def each_rate(&block)
      enum = Enumerator.new do |yielder|
        index.each do |key, rate|
          iso_from, iso_to = key.split(Memory::INDEX_KEY_SEPARATOR)
          iso_to, date = iso_to.split("_")
          date = Date.parse(date) if date
          yielder.yield iso_from, iso_to, rate, date
        end
      end

      block_given? ? enum.each(&block) : enum
    end

    private

      def rate_key_for(currency_iso_from, currency_iso_to, date = nil)
        key = [currency_iso_from, currency_iso_to].join(Memory::INDEX_KEY_SEPARATOR)
        key << "_#{date.to_s}" if date
        key.upcase
      end

  end
end