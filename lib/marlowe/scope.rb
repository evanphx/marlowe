require 'marlowe/parser'
require 'marlowe/c_import'
require 'marlowe/class_wrapper'

module Marlowe
  class Scope
    def initialize(parent=nil)
      @parent = parent
      @identifiers = {}
      @functions = {}
      @types = {}
      @importer = nil
      @classes = {}
    end

    attr_accessor :importer
    attr_reader :identifiers, :functions, :parent

    def self.root
      scope = Scope.new
      scope.add_type Type.new("void", :void)

      scope.add_type IntegerType.new('int8', :char)
      scope.add_type IntegerType.new('uint8', :uchar)
      scope.add_type IntegerType.new('int16', :short)
      scope.add_type IntegerType.new('uint16', :ushort)
      scope.add_type IntegerType.new('int32', :int32)
      scope.add_type IntegerType.new('uint32', :uint32)
      scope.add_type IntegerType.new('int64', :int64)
      scope.add_type IntegerType.new('uint64', :uint64)

      scope.add_type IntegerType.new('int', :int)
      scope.add_type IntegerType.new('uint', :uint)

      scope.add_type Type.new("unknown")
      return scope
    end

    def add_type(type)
      @types[type.name] = type
    end

    def type(name)
      if @types.key?(name)
        @types[name]
      elsif @parent
        @parent.type(name)
      end
    end

    def find(name)
      if i = @identifiers[name]
        return i
      end

      if i = @functions[name]
        return i
      end

      return @parent.find_identifier(name) if @parent
    end

    def import(code)
      @parser = Parser.new(code)
      unless @parser.parse
        @parser.show_fixit
        raise "Unable to parse code"
      end

      @parser.declarations.each do |decl|
        case decl
        when ImportDeclaration
          @identifiers[decl.local_name] = @importer.import decl.pieces
        when FromDeclaration
          c = Marlowe::CImport.new(self, decl.file_path)

          decl.declarations.each do |b|
            @functions[b.method_name] = c.function(b.func_name)
          end
        end
      end
    end

    def package
      @parser.package
    end

    def find_class(name)
      decl = @parser.declarations.find do |cls|
        cls.kind_of?(ClassDeclaration) and cls.name == name
      end

      @classes[name] ||= ClassWrapper.new(self, name, decl)
    end
  end
end
