# Supress Warnings
warn_level = $VERBOSE
$VERBOSE = nil

require 'coveralls'
Coveralls.wear!

require 'simplecov'
require 'simplecov-rcov'

SimpleCov.formatter = SimpleCov::Formatter::RcovFormatter
SimpleCov.start do
  add_filter '/spec/'
end

require 'json2ruby'