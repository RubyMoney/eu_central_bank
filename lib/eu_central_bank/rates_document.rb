class EuCentralBank < Money::Bank::VariableExchange
  class RatesDocument < Nokogiri::XML::SAX::Document
    attr_reader :rates
    attr_reader :errors
    attr_reader :updated_at

    def initialize
      @rates = {}
      @errors = []
      @updated_at = nil
      @current_date = nil
    end

    def error(msg)
      # TODO: remove this workaround after
      # https://github.com/sparklemotion/nokogiri/pull/1872
      # is released
      @errors << msg
      super
    end

    def start_element(name, attributes=[])
      return if name != 'Cube' || attributes.empty?
      begin
        first_name, first_value = attributes[0]
        case first_name
        when 'time'
          @current_date = Time.parse(first_value).to_date
          @updated_at ||= @current_date
          @rates[@current_date] = []
        when 'currency'
          currency = first_value
          _, rate = attributes[1]
          @rates[@current_date] << [currency, rate]
        end
      rescue StandardError => e
        raise Nokogiri::XML::XPath::SyntaxError, e.message
      end
    end

    def end_document
      raise Nokogiri::XML::XPath::SyntaxError if @rates.empty? || @updated_at.nil?
    end
  end
end
