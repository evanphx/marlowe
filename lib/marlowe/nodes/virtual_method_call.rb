require 'marlowe/nodes/node'

module Marlowe
  class Nodes::VirtualMethodCall < Nodes::Node
    def initialize(index, receiver)
      @index = index
      @receiver = receiver
    end

    def run(cf)
    end
  end
end
