module Marlowe::C
  class Generator
    def initialize(env, name=nil)
      @env = env
      @name = name
    end

    def type_named(type)
      return type.flat_name
    end
  end

  class Marlowe::C::Env
  end

  class StackAllocate < Generator
    def initialize(env, type, name=nil)
      super(env, name)
      @type = type
    end

    def value
      @name
    end

    def generate
      "#{type_named(@type)} #{value}"
    end
  end

  class IntegerLiteral < Generator
    def initialize(env, val)
      super(env, nil)
      @value = val
    end

    def value
      "#{@value}"
    end

    def generate
      nil
    end
  end

  class LocalAssignment < Generator
    def initialize(env, local, value)
      super(env, nil)
      @local = local
      @value = value
    end

    def value
      @local.name
    end

    def generate
      if code = @value.generate
        str = "#{code};\n"
      else
        str = ""
      end

      str << "#{@local.name} = #{@value.value}"
    end
  end

  class InstanceVariableAssignment < Generator
    def initialize(env, local, value)
      super(env, nil)
      @local = local
      @value = value
      @exposed_value = env.next_temp
    end

    def value
      @exposed_value
    end

    def generate
      if code = @value.generate
        str = "#{code);\n"
      else
        str = ""
      end

      str << "self->#{@ivar.name} = 
end
