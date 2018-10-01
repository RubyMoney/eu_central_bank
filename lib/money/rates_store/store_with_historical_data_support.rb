module Money::RatesStore
  class StoreWithHistoricalDataSupport < Money::RatesStore::Memory
    INDEX_DATE_SEPARATOR = '_AT_'.freeze

    def add_rate(currency_iso_from, currency_iso_to, rate, date = nil)
      transaction { index[rate_key_for(currency_iso_from, currency_iso_to, date)] = rate }
    end

    def get_rate(currency_iso_from, currency_iso_to, date = nil)
      transaction { index[rate_key_for(currency_iso_from, currency_iso_to, date)] }
    end

    # Wraps block execution in a thread-safe transaction
    def transaction(force_sync = false, &block)
      # Ruby 1.9.3 does not support @mutex.owned?
      if @mutex.respond_to?(:owned?)
        force_sync = false if @mutex.locked? && @mutex.owned?
      else
        # If we allowed this in Ruby 1.9.3, it might possibly cause recursive
        # locking within the same thread.
        force_sync = false
      end
      if !force_sync && (@in_transaction || options[:without_mutex])
        block.call self
      else
        @mutex.synchronize do
          @in_transaction = true
          result = block.call
          @in_transaction = false
          result
        end
      end
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
    #   store.each_rate do |iso_from, iso_to, rate, date|
    #     puts [iso_from, iso_to, rate, date].join
    #   end
    def each_rate(&block)
      enum = Enumerator.new do |yielder|
        index.each do |key, rate|
          iso_from, iso_to = key.split(Memory::INDEX_KEY_SEPARATOR)
          iso_to, date = iso_to.split(INDEX_DATE_SEPARATOR)
          date = Date.parse(date) if date
          yielder.yield iso_from, iso_to, rate, date
        end
      end

      block_given? ? enum.each(&block) : enum
    end

    private

      def rate_key_for(currency_iso_from, currency_iso_to, date = nil)
        key = [currency_iso_from, currency_iso_to].join(Memory::INDEX_KEY_SEPARATOR)
        key = [key, date.to_s].join(INDEX_DATE_SEPARATOR) if date
        key.upcase
      end
  end
end
