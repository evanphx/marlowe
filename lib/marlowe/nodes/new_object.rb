require 'marlowe/nodes/node'
require 'marlowe/values'

module Marlowe
  class Nodes::NewObject < Nodes::Node
    def initialize(type)
      @type = type
    end

    def run(cf)
      Instance.new(@type)
    end
  end
end
