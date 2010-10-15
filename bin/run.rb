$:.unshift File.expand_path("../lib", __FILE__)
require 'rubygems'
require 'marlowe/interp'

file = ARGV.shift
cls = ARGV.shift

raise "specify a class to find main on" unless cls

puts "Running: #{file} for #{cls}"

interp = Marlowe::Interpreter.new
interp.run(file, cls)
