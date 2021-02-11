# eu_central_bank

[![Build Status](https://travis-ci.org/RubyMoney/eu_central_bank.svg?branch=master)](https://travis-ci.org/RubyMoney/eu_central_bank)

## Introduction

This gem downloads the exchange rates from the European Central Bank. You can calculate exchange rates with it. It is compatible with the money gem.

## Installation

```
gem install eu_central_bank
```

In case you're using older ruby (< 2.1) you need nokogiri < 1.6.8, so add this to your `Gemfile`:

```
gem 'nokogiri', '1.6.8'
```

## Dependencies

- nokogiri
- money

## Usage

With the gem, you do not need to manually add exchange rates. Calling `update_rates` will download the rates from the European Central Bank. The API is the same as the money gem. Feel free to use Money objects with the bank.

``` ruby
require 'eu_central_bank'
eu_bank = EuCentralBank.new
Money.default_bank = eu_bank
money1 = Money.new(10)
money1.bank # eu_bank

# call this before calculating exchange rates
# this will download the rates from ECB
eu_bank.update_rates

# exchange 100 CAD to USD
# API is the same as the money gem
eu_bank.exchange(100, "CAD", "USD") # Money.new(80, "USD")
Money.us_dollar(100).exchange_to("CAD")  # Money.new(124, "CAD")

# using the new exchange_with method
eu_bank.exchange_with(Money.new(100, "CAD"), "USD") # Money.new(80, "USD")
```

For performance reasons, you may prefer to read from a file instead. Furthermore, ECB publishes their rates daily. It makes sense to save the rates in a file to read from. It also adds an `updated_at` field so that you can manage the update.

``` ruby
# cached location
cache = "/some/file/location/exchange_rates.xml"

# saves the rates in a specified location
eu_bank.save_rates(cache)

# reads the rates from the specified location
eu_bank.update_rates(cache)

if !eu_bank.rates_updated_at || eu_bank.rates_updated_at < Time.now - 1.days
  eu_bank.save_rates(cache)
  eu_bank.update_rates(cache)
end

# exchange 100 CAD to USD as usual
eu_bank.exchange_with(Money.new(100, "CAD"), "USD") # Money.new(80, "USD")
```

## Note on Patches/Pull Requests

- Fork the project.
- Make your feature addition or bug fix.
- Add tests for it. This is important so I don't break it in a  future version unintentionally.
- Commit, do not mess with rakefile, version, or history. (if you want to have your own version, that is fine but bump version in a commit by itself I can ignore when I pull)

## Copyright

Copyright (c) 2010-2016 RubyMoney. See LICENSE for details.
