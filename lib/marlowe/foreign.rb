module Marlowe
  class ForeignFunction
    def initialize(name, type)
      @name = name
      @type = type
      @execute = nil
    end

    def execute(&bl)
      @execute = bl
    end

    def run(c, arguments)
      @type.validate(c, arguments)
      @execute.call(c, *arguments)
    end
  end
end
