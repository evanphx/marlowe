require 'marlowe/nodes/node'

module Marlowe
  class Nodes::StringLiteral < Nodes::Node
    def initialize(data, type)
      @data = data
      @type = type
    end

    def run(cf)
      StaticString.new(@type, @data)
    end
  end
end
