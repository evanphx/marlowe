module Marlowe
  module C
    class Function
      def initialize(name, sig)
        @name = name
        @signature = sig
      end

      attr_reader :name, :signature
    end
  end
end
