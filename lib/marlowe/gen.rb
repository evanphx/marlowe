require 'marlowe/type'

module Marlowe
  class GenerationState
    def initialize(cres, binding)
      @cres = cres
      @binding = binding

      @c_types = TypeRegistry.new
      @c_types.add_type IntegerType.new("int")
      @c_types.add_type IntegerType.new("char")
    end

    def find_c_type(name)
      if t = @c_types[name]
        return t
      end

      if name[-1] == ?*
        sub = find_c_type(name[0..-2])
        t = PointerType.new(sub)
        @c_types.add_type t
        return t
      end

      raise "unknown type: #{name}"
    end

    def find_c_function(name)
      @cres.find_function(name)
    end
  end

  class Binding
    def initialize
      @variables = {}
    end

    def add_binding(name, type)
      @variables[name] = type
    end
  end
end
