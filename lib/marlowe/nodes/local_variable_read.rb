require 'marlowe/nodes/node'

module Marlowe
  class Nodes::LocalVariableRead  < Nodes::Node
    def initialize(index)
      @index = index
    end

    def run(call_frame)
      call_frame.locals[@index]
    end
  end
end
