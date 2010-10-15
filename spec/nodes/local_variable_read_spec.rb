require 'spec/helper'
require 'marlowe/scope'
require 'marlowe/nodes/local_variable_read'
require 'marlowe/c/function'
require 'marlowe/nodes/integer_literal'
require 'marlowe/method'

describe Marlowe::Nodes::LocalVariableRead do
  it "reads a local variable out of the current call frame" do
    scope = Marlowe::Scope.root

    lr = Marlowe::Nodes::LocalVariableRead.new(0)
    cf = Marlowe::Method::CallFrame.new(1)

    int = Marlowe::Integer.new scope.type("int"), 10
    cf.locals[0] = int

    lr.run(cf).should == int
  end
end
