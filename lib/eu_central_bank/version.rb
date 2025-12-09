# frozen_string_literal: true

require "money"

class EuCentralBank < Money::Bank::VariableExchange
  VERSION = "2.0.0"
end
