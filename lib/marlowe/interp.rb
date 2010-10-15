require 'ffi'

require 'marlowe/type'
require 'marlowe/foreign'
require 'marlowe/parser'
require 'marlowe/class'
require 'marlowe/file'

module Marlowe
  class Interpreter

    class CallFrame
      def initialize(method)
        @method = method
        @local_vals = {}
        @local_types = {}
      end

      def set_local(name, type, val)
        @local_vals[name] = val
        @local_types[name] = type
      end
    end

    class ForeignMethod
      def initialize(name)
        @name = name
      end

      def bind(f_name, args, ret_type)
        @sig = TypeSignature.new(ret_type)
        args.each { |x| @sig << x }

        lib = FFI::DynamicLibrary.new(nil, 0)
        sym = lib.find_function(f_name)
        ffi_args = args.map { |x| x.to_ffi }
        @func = FFI::Function.new(ret_type.to_ffi, ffi_args, sym)
      end

      def run(c, arguments)
        @sig.validate(c, arguments)

        vals = arguments.map { |x| x.run(c) }
        @func.call(*vals)
      end
    end

    class Package
      def initialize(name)
        @name = name
        @types = {}
        @packages = {}
      end

      attr_reader :name

      def add_type(t)
        @types[t.name] = t
      end

      def find_type(name)
        @types[name]
      end

      def add_package(k)
        @packages[k.name] = k
      end

      def find_package(name)
        @packages[name]
      end
    end

    class Context
      def initialize(interp)
        @interp = interp
        @package = nil
        @current_class = nil
        @classes = {}

        @current_self = nil

        @imports = {}

        @current_callframe = nil
      end

      attr_reader :package, :current_class, :current_callframe

      def int32
        @interp.int32
      end

      def in_class(cls)
        old = @current_class
        @current_class = cls

        begin
          yield
        ensure
          @current_class = old
        end
      end

      def find_class(name)
        @classes[name]
      end

      def in_self(obj)
        old = @current_self
        @current_self = obj

        begin
          yield
        ensure
          @current_self = old
        end
      end

      def in_callframe(obj)
        old = @current_callframe
        @current_callframe = obj

        begin
          yield
        ensure
          @current_callframe = old
        end
      end

      def find_foreign(name)
        @interp.find_foreign(name)
      end

      def find_type(name)
        @interp.find_type(name)
      end

      module Foreign
        extend FFI::Library

        ffi_lib "libc"

        attach_function :strdup, [:string], :pointer
      end

      extend Foreign

      def new_string(data)
        Foreign.strdup data
      end

      def lookup_method(name)
        if @current_self.kind_of?(Class)
          @current_self.find_singleton_method(name)
        else
          raise "aoeu"
        end
      end
    end

    attr_reader :root_package, :int32

    def initialize
      prelude
      @load_path = ["mcl"]
      @trees = Hash.new
    end

    def find_package(parts)
      pkg = @root_package
      parts.each do |path|
        pkg = pkg.find_package(path)
      end

      return pkg
    end

    def find_path(pieces)
      @load_path.each do |root|
        ary_path = pieces.dup

        until ary_path.empty?
          path = ::File.join(root, *ary_path) + ".mrl"
          return path if ::File.exists?(path)
          ary_path.pop
        end
      end

      raise "Unable to find path for: #{pieces.inspect}"
    end

    def import(pieces)
      file = find_path(pieces)

      tree = @trees[file]

      return tree if tree

      fo = File.new(file)
      fo.process(self)

      @trees[file] = fo

      fo
    end

    def find_foreign(name)
      @foreign[name]
    end

    def find_type(name)
      @types[name]
    end

    def prelude
      root = Package.new(".")
      sys = Package.new("system")

      root.add_package(sys)

      i8 = Type.new("Int8", :char)
      sys.add_type(i8)

      @int32 = Type.new("Int32", :int)
      sys.add_type(@int32)

      @root_package = root

      str = Class.new("marlowe.String")

      @types = {
        :void => Type.new("void"),
        :string => i8.pointer_to
      }

      sig = TypeSignature.new(@types[:void])
      sig << @types[:string]

      puts = ForeignFunction.new("puts", sig)

      puts.execute do |c,str|
        STDOUT.puts str.run(c).as_ruby
      end

      @foreign = {
        "puts" => puts
      }
    end

    def run(file, class_name)
      file = Marlowe::File.new(file)

      unless file.parser.successful?
        puts
        file.parser.show_fixit
        raise Marlowe::ParseError
      end

      file.process(self)

      cls = c.find_class(class_name)
      main = cls.find_singleton_method("main")

      c.in_self(cls) do
        main.run(c)
      end
    end
  end
end
