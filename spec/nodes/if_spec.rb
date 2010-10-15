require 'spec/helper'
require 'marlowe/nodes/if'
require 'marlowe/nodes/bool'
require 'marlowe/nodes/integer'
require 'marlowe/scope'

describe Marlowe::Nodes::If do
  it "runs the then branch if the condition is true" do
    scope = Marlowe::Scope.root

    cond = Marlowe::Nodes::True.new
    i1 = Marlowe::Nodes::Integer.new(5, scope.type("int"))

    i = Marlowe::Nodes::If.new(cond, i1)

    i.run(nil).value.should == 5
  end

  it "runs the else branch if the condition is true" do
    scope = Marlowe::Scope.root

    cond = Marlowe::Nodes::False.new
    i1 = Marlowe::Nodes::Integer.new(5, scope.type("int"))
    i2 = Marlowe::Nodes::Integer.new(10, scope.type("int"))

    i = Marlowe::Nodes::If.new(cond, i1, i2)

    i.run(nil).value.should == 10
  end
end
