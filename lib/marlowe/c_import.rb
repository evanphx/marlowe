require 'rubygems'
require 'rbgccxml'
require 'pp'
require 'marlowe/type'

module RbGCCXML
  class PointerType
    def pointed_to_type
      XMLParsing.find_type_of(self.node, "type")
    end
  end

  class Typedef
    def sub_type
      XMLParsing.find_type_of(self.node, "type")
    end
  end

  class CvQualifiedType
    def sub_type
      XMLParsing.find_type_of(self.node, "type")
    end
  end

  class ArrayType
    def element_type
      XMLParsing.find_type_of(self.node, "type")
    end
  end
end

module Marlowe
  class CImport
    def resolve_type(t)
      case t
      when RbGCCXML::PointerType
        resolve_type(t.pointed_to_type).pointer_to
      when RbGCCXML::FundamentalType
        case t.name
        when "int"
          @scope.type("int")
        when "unsigned int"
          @scope.type("uint")
        when "short int"
          @scope.type("int16")
        when "short unsigned int"
          @scope.type("uint16")
        when "char"
          @scope.type("int8")
        when "unsigned char"
          @scope.type("uint8")
        when "long long int"
          @scope.type("int64")
        when "unsigned long long int"
          @scope.type("uint64")
        when "void"
          @scope.type("void")
        else
          puts "WARNING: treating #{t.name} as int"
          @scope.type("int")
        end
      when RbGCCXML::Typedef
        @scope.add_type AliasType.new(t.name, resolve_type(t.sub_type))
      when RbGCCXML::Struct
        @scope.add_type create_struct(t)
      when RbGCCXML::CvQualifiedType
        resolve_type t.sub_type
      when RbGCCXML::FunctionType
        @scope.type("void")
      when RbGCCXML::ArrayType
        max = t["max"].to_i
        Marlowe::CArrayType.new t.name, t.element_type, max
      else
        raise "Unimplemented type - #{t.class}"
      end
    end

    def create_struct(t)
      st = Marlowe::StructType.new(t.name)

      t.variables.each do |var|
        st.add var.name, resolve_type(var.cpp_type)
      end

      st
    end

    def initialize(scope, file)
      @parsed = RbGCCXML.parse(file)
      @scope = scope
    end

    class Function
      def initialize(name, args, ret)
        @name = name
        @arguments = args
        @ret_type = ret
      end

      attr_reader :name, :arguments, :ret_type
    end

    def function(func)
      obj = @parsed.functions(func)

      unless obj
        raise NameError, "Unable to find #{func}"
      end

      args = obj.arguments.map do |arg|
        resolve_type(arg.cpp_type)
      end

      Function.new(func, args, resolve_type(obj.return_type))
    end
  end
end

=begin

s = Scope.new

c = Marlowe::CImport.new(s, "/usr/include/stdio.h")

pp c.add_function("fopen")

=end
