module Marlowe
  class Type
    def initialize(name)
      @name = name
    end

    attr_reader :name
  end

  class IntegerType < Type
    def to_c(g)
      name
    end
  end

  class PointerType < Type
    def initialize(type)
      @subtype = type
      @name = "#{type.name}*"
    end

    attr_reader :subtype

    def to_c(g)
      "#{@subtype.to_c(g)}*"
    end
  end

  class TypeRegistry
    def initialize
      @types = {}
    end

    def add_type(type)
      @types[type.name] = type
    end

    def [](name)
      @types[name]
    end
  end
end
