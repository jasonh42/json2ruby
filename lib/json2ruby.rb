files = [
  'version',
  'primitive',
  'attribute',
  'collection',
  'entity',
  'ruby_writer',
  'factory_writer',
  'cli',
].each { |file| require "#{File.dirname(__FILE__)}/json2ruby/#{file}" }
