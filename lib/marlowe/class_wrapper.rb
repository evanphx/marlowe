require 'marlowe/bound_method'

module Marlowe
  class ClassWrapper
    def initialize(scope, name, decl)
      @scope = scope
      @name = name
      @decl = decl
    end

    attr_reader :name, :scope

    def declared_methods
      @decl.declared_methods
    end

    def bind(name)
      mo = declared_methods.find { |m| m.name == name }
      if mo
        return BoundMethod.new(self, mo)
      end

      nil
    end
  end
end
