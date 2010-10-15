require 'marlowe/nodes/node'
require 'marlowe/bool'
require 'marlowe/nodes/void'

module Marlowe
  class Nodes::If < Nodes::Node
    def initialize(cond, thn, els=Marlowe::Nodes::Void.new)
      @condition = cond
      @then = thn
      @else = els
    end

    def run(cf)
      if @condition.run(cf).kind_of? Marlowe::True
        @then.run(cf)
      else
        @else.run(cf)
      end
    end
  end
end
