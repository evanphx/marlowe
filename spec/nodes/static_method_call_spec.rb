require 'spec/helper'
require 'marlowe/nodes/static_method_call'
require 'marlowe/scope'
require 'marlowe/nodes/integer_literal'
require 'marlowe/nodes/local_variable_read'
require 'marlowe/method'

describe Marlowe::Nodes::StaticMethodCall do
  it "invokes a method with the reciever as the first local" do
    scope = Marlowe::Scope.root

    sig = Marlowe::TypeSignature.new scope.type("int")
    sig << scope.type("int") 

    int = Marlowe::Nodes::IntegerLiteral.new(10, scope.type("int"))

    body = Marlowe::Nodes::LocalVariableRead.new(0)

    meth = Marlowe::Method.new "test", body, sig

    node = Marlowe::Nodes::StaticMethodCall.new(meth, int)

    node.run(nil).value.should == 10
  end
end
