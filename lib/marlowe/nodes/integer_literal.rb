require 'marlowe/nodes/node'
require 'marlowe/values'

module Marlowe
  class Nodes::IntegerLiteral < Nodes::Node
    def initialize(val, type)
      @value = val
      @type = type
    end

    def run(cf)
      Integer.new(@type, @value)
    end
  end
end
