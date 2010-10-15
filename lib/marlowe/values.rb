module Marlowe
  class Value
    def initialize(type)
      @type = type
    end

    attr_reader :type
  end

  class Integer < Value
    def initialize(type, val)
      super type
      @value = val
    end

    attr_reader :value

    def ffi_value
      @value
    end
  end

  class StaticString < Value
    def initialize(type, val)
      super type
      @value = val
    end

    attr_reader :value

    def ffi_value
      @value
    end
  end

  class Instance < Value
  end
end

