module Marlowe
  class ArgCountMismatchError < RuntimeError
  end

  class Method
    def initialize(name, body=nil, type_sig=TypeSignature.new(nil))
      @name = name
      @arguments = nil
      @body = body
      @signature = type_sig
    end

    attr_accessor :name, :arguments, :body, :signature

    def run(*args)
      if args.size != @signature.total_args
        raise ArgCountMismatchError
      end

      cf = CallFrame.new(args.size)
      args.each_with_index do |a,i|
        cf.locals[i] = a
      end

      @body.run(cf)
    end

    def ret_type
      @signature.return ||= @body.type
    end

    class CallFrame
      def initialize(locals)
        @locals = Array.new(locals)
      end

      attr_reader :locals
    end

    def old_run(c, *args)
      @arguments ||= []

      if args.size != @arguments.size
        raise "Arity mismatch: #{args.size} != #{@arguments.size}"
      end

      cf = CallFrame.new(self)

      c.in_callframe(cf) do
        @body.each do |x|
          x.run(c)
        end
      end
    end
  end
end
