module Marlowe
  class File
    def initialize(path)
      @path = path

      code = ::File.read(path)
      @parser = Parser.new(code)
      @classes = {}
      @scope = {}

      @package = nil

      @parser.parse
    end

    attr_reader :scope, :parser, :package

    def package=(pkg)
      if @package
        raise Marlowe::ParseError, "Already defined package to '#{@package}'"
      end

      @package = pkg
    end

    def add_class(name, cls)
      @classes[name] = cls
    end

    def process(c)
      puts "processing #{@path}"
      @parser.declarations.each do |decl|
        decl.declare(c, self)
      end
    end
  end
end
