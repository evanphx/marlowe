module Marlowe

  class TypeCheckFailed < RuntimeError
  end

  class TypeMismatchError < RuntimeError
  end

  class Type
    def initialize(name, ffi_type=nil)
      @name = name
      @pointer_to = nil
      @ffi_type = ffi_type
    end

    attr_reader :name, :ffi_type

    def to_ffi
      raise "No ffi type set for #{self}" unless @ffi_type
      @ffi_type
    end

    def pointer_to
      @pointer_to ||= PointerType.new(self)
    end
  end

  class UnknownType < Type
  end

  class AliasType < Type
    def initialize(name, sub)
      super name
      @subtype = sub
    end

    attr_reader :subtype
  end

  class IntegerType < Type
    def to_c(g)
      name
    end
  end

  class PointerType < Type
    def initialize(type)
      super "#{type.name}*"
      @subtype = type
    end

    attr_reader :subtype

    def to_ffi
      :pointer
    end

    def to_c(g)
      "#{@subtype.to_c(g)}*"
    end
  end

  class StructType < Type
    def initialize(name)
      super
      @members = []
    end

    class Field
      def initialize(name, type)
        @name = name
        @type = type
      end

      attr_reader :name, :type
    end

    def add(name, type)
      @members << Field.new(name, type)
    end
  end

  class CArrayType < Type
    def initialize(name, element_type, size)
      super(name)
      @element_type
      @size = size
    end

    attr_reader :element_type, :size
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

  class TypeSignature
    def initialize(ret)
      @return = ret
      @arguments = []
    end

    attr_reader :return, :arguments

    def return=(val)
      return if val == @return

      if !@return or @return.kind_of?(UnknownType)
        @return = val
      else
        raise TypeMismatchError, "return type already set"
      end
    end

    def total_args
      @arguments.size
    end

    def <<(arg)
      @arguments << arg
    end

    def validate(c, incoming)
      @arguments.zip(incoming) do |type, val|
        val_type = val.interp_type(c)

        unless type == val_type
          raise "type mismatch #{type} != #{val_type}"
        end
      end
    end
  end
end
