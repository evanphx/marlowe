$:.unshift File.expand_path("../lib", __FILE__)
require 'rubygems'
require 'marlowe/parser'
require 'pp'

path = ARGV.shift
text = File.read(path)

parser = Marlowe::Parser.new(text)
parser.parse

unless parser.successful?
  puts
  parser.show_fixit
  raise Marlowe::ParseError
end

pp parser.to_sexp
