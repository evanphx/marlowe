require 'treetop'
require 'marlowe/nodes'

Treetop.load File.expand_path("../grammar.treetop", __FILE__)

module Marlowe
  class ParseError < SyntaxError; end

  class Parser
    def initialize(text)
      @parser = GrammarParser.new
      @code = text
    end

    def parse
      if @toplevel = @parser.parse(@code)
        @toplevel.declarations.each_with_index do |ele, i|
          case ele
          when PackageDeclaration
            if i != 0
              raise ParseError, "package declaration wasn't first"
            end
          end
        end
      end

      @toplevel
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
      [:marlowe] + @toplevel.declarations.map { |x| x.to_sexp }
    end

    def declarations
      @toplevel.declarations
    end

    def package
      first = @toplevel.declarations.first

      if first.kind_of? PackageDeclaration
        return first.name
      end

      return nil
    end

    def find(what)
      @toplevel.declarations.each do |decl|
        if decl.kind_of? ClassDeclaration
          return decl if decl.name == what
        end
      end

      return nil
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
