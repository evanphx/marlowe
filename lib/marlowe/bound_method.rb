module Marlowe
  class BoundMethod
    def initialize(cw, decl)
      @class = cw
      @decl = decl
    end

    def name
      @decl.name
    end

    def expressions
      @decl.expressions
    end

    def scope
      @class.scope
    end
  end
end
