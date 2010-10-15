require 'marlowe/nodes/node'
require 'marlowe/nodes/static_function_call'

module Marlowe
  class Nodes::StaticMethodCall < Nodes::StaticFunctionCall
    def initialize(target, recv)
      @target = target
      @arguments = [recv]
    end
  end
end
