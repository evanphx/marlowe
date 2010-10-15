require 'marlowe/type'
require 'marlowe/method'

module Marlowe
  class MObject
    def initialize(cls)
      @klass = cls
    end

    attr_reader :klass
  end

  class Class < Type
    def initialize(name, instance_class=MObject)
      super name
      @instance_class = instance_class
      @methods = []
      @singleton_methods = {}
      @ivars = []
    end

    def add_method(meth)
      idx = @methods.size
      @methods << meth
      idx
    end

    def new_method(name)
      m = Method.new(name)
      @methods[name] = m
      return m
    end

    def new_singleton_method(name)
      m = Method.new(name)
      @singleton_methods[name] = m
      return m
    end

    def find_singleton_method(name)
      @singleton_methods[name]
    end

    def new_instance
      @instance_class.new(self)
    end

    def bind_foreign_singleton_method(m_name, f_name, types, ret_type)
      m = ForeignMethod.new(m_name)
      @singleton_methods[m_name] = m

      m.bind(f_name, types, ret_type)
      return m
    end

    def bind_foreign_method(m_name, f_name, types, ret_type)
      m = ForeignMethod.new(m_name)
      @methods[m_name] = m

      m.bind(f_name, types, ret_type)
      return m
    end

    def add_ivar(name, type)
      @ivars << [name, type]
    end
  end

  class TypeClass < Class
    def initialize(name)
      super

      @type_params = nil
    end

    attr_accessor :type_params
  end


end
