require 'spec/helper'
require 'marlowe/nodes/virtual_method_call'
require 'marlowe/scope'
require 'marlowe/nodes/integer_literal'
require 'marlowe/nodes/new_object'
require 'marlowe/class'
require 'marlowe/method'

describe Marlowe::Nodes::VirtualMethodCall do
  it "looks up the method at runtime to invoke" do
    scope = Marlowe::Scope.root

    sig = Marlowe::TypeSignature.new scope.type("int")

    int = Marlowe::Nodes::IntegerLiteral.new(10, scope.type("int"))
    meth = Marlowe::Method.new "test", int, sig

    int2 = Marlowe::Nodes::IntegerLiteral.new(20, scope.type("int"))
    meth2 = Marlowe::Method.new "test", int2, sig

    cls1 = Marlowe::Class.new "Test1"
    cls1.add_method meth

    obj = Marlowe::Nodes::NewObject.new(cls1)

    node = Marlowe::Nodes::VirtualMethodCall.new(0, obj)

    node.run(nil).value.should == 10

  end
end
