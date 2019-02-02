# eu_central_bank changelog

## 1.4.2 (Feb 2 2019)

* Fix issue with importing exported rates

## 1.4.1 (Jan 14 2019)

* Relax Nokogiri dependency to `~> 1.8` on newer rubies

## 1.4.0 (Dec 17 2018)

* Update money dependency to 6.13.x
* Relax money dependency to a minor version

## 1.3.1 (Sep 6 2018)

* Fix HTTPS redirection error

## 1.3.0 (Jun 12 2018)

* Add configurable rates store
* Add support for Icelandic Krona (ISK)
* Bump money dependency to 6.11

## 1.2.0 (Dec 29 2017)

* Bump money dependency to 6.10.1

## 1.1.3 (Mar 24 2017)

* Fix a bug in #check_currency_available
* Update money dependency to 6.9.0

## 1.1.2 (Mar 24 2017)

* Update nokogiri dependency to 1.7.1 to avoid vulnerability

## 1.1.1 (Jan 28 2017)

* Fix nokogiri dependency issue with ruby 2.4.0

## 1.1.0 (Jan 19 2017)

* Added support for ruby 2.3.0 and 2.4.0
* Fixed ruby warnings
* Fixed thread safety issue
* Fixed issue with historical rates
* Added exception for currencies not in the list

## 1.0.1 (May 20 2016)

* Fixed compatibility with recent Money gem

## 1.0.0 (Jan 15 2016)

* Update to Money 6.7.0
* Not Support for LTL
* Fix a couple of Ruby warnings found in specs

## 0.3.8 (Feb 12 2014)

* Updated money version

## 0.3.6 (Sep 4 2013)

* Bank url change
* fix ruby-version warning

## 0.3.0 (Jan 29 2012)

* Updated Money dependency to 4.0.1
* Fixed deprecated rake tasks

## 0.2.4 (Sep 14 2011)

* Merged pull request #6: support currencies without subunits

## 0.2.3 (Sep 8 2011)

* Updated Nokogiri dependency to 1.5.0

## 0.2.2 (Jul 13 2011)

* Fixed #2 versioning bug

## 0.2.1 (Jul 13 2011-yanked)

* Updated dependencies to run with Money 3.7.x

## 0.2.0 (Feb 19 2011)

* Changed to use rounding instead of flooring dues to issues with negative number amounts

## 0.1.5 (Jan 18 2011)

* Updated the money dependency on the gemspec

## 0.1.4 (Jan 18 2011)

* Removed the Estonian Kroon from the list of currencies as EU Central Bank does not list it anymore

## 0.1.3 (December 18 2010)

* Fixed the gemspec bug

## 0.1.2 (December 15 2010)

* Clean up dependencies

## 0.1.1 (July 17 2010)

* Added the exchange_with method from money gem

## 0.1.0 (April 21 2010)

* Initial gem release
