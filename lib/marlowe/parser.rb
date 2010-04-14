require 'treetop'
require 'marlowe/nodes'

Treetop.load File.expand_path("../grammar.treetop", __FILE__)

module Marlowe
  class Parser
    def initialize(text)
      @parser = GrammarParser.new
      @code = text
    end

    def parse
      @toplevel = @parser.parse(@code)
    end

    def successful?
      !!@toplevel
    end

    def failure_reason
      @parser.failure_reason
    end

    def code_lines
      @code.split("\n")
    end

    def show_fixit
      expected = @parser.terminal_failures.map { |f| f.expected_string.dump }.uniq

      line = @parser.failure_line - 1
      line_marker = "#{line + 1}: "

      if line > 0
        print " " * line_marker.size
        puts code_lines[line - 1]
      end
      print line_marker
      puts code_lines[line]

      print " " * line_marker.size
      print(" " * (@parser.failure_column - 1))
      puts "^"
      puts "Expected one of: #{expected.join(", ")}"
    end

    def to_sexp
      [:marlowe] + @toplevel.classes.map { |x| x.to_sexp }
    end

    def to_xml(io)
      io.puts "<marlowe>"
      @toplevel.classes.each do |top|
        top.to_xml(io)
      end
      io.puts "</marlowe>"
    end
  end
end
