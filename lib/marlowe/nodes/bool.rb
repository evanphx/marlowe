require 'marlowe/nodes/node'
require 'marlowe/bool'

module Marlowe
  class Nodes::True < Nodes::Node
    def run(cf)
      Marlowe::True.new
    end
  end

  class Nodes::False < Nodes::Node
    def run(cf)
      Marlowe::False.new
    end
  end
end
