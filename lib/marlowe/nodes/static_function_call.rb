require 'marlowe/nodes/node'
require 'ffi'
require 'marlowe/c/function'

module Marlowe
  class Nodes::StaticFunctionCall
    def initialize(target)
      @target = target
      @arguments = []
    end

    def <<(val)
      @arguments << val
    end

    def ffi_call(vals)
      lib = ::FFI::DynamicLibrary.new(nil, 0)
      sym = lib.find_function(@target.name)
      sig = @target.signature
      ffi_ret  = sig.return.to_ffi
      ffi_args = sig.arguments.map { |x| x.to_ffi }

      func = ::FFI::Function.new(ffi_ret, ffi_args, sym)

      func.call(*vals)
    end

    def type_check
      sig = @target.signature

      sig.arguments.zip(@arguments) do |type, val|
        return false unless type == val.type
      end

      return true
    end

    def run(cf)
      raise TypeCheckFailed unless type_check

      case @target
      when Marlowe::C::Function
        vals = @arguments.map { |x| x.run(cf).ffi_value }
        ffi_call vals
      else
        vals = @arguments.map { |x| x.run(cf) }
        @target.run(*vals)
      end
    end
  end
end
