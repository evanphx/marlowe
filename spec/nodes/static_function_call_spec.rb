require 'spec/helper'
require 'marlowe/scope'
require 'marlowe/nodes/static_function_call'
require 'marlowe/c/function'
require 'marlowe/nodes/string_literal'
require 'marlowe/nodes/integer_literal'
require 'marlowe/method'

describe Marlowe::Nodes::StaticFunctionCall do
  it "can use FFI to call an external function" do
    scope = Marlowe::Scope.root

    int = scope.type("int")
    sig =  Marlowe::TypeSignature.new int
    sig << scope.type("int8").pointer_to

    ext =  Marlowe::C::Function.new("atoi", sig)
    node = Marlowe::Nodes::StaticFunctionCall.new(ext)

    node.ffi_call("10").should == 10
  end

  it "invokes the target when run" do
    scope = Marlowe::Scope.root

    int = scope.type("int")
    sig =  Marlowe::TypeSignature.new int
    charp = scope.type("int8").pointer_to 
    sig << charp

    ext =  Marlowe::C::Function.new("atoi", sig)

    node = Marlowe::Nodes::StaticFunctionCall.new(ext)
    node << Marlowe::Nodes::StringLiteral.new("10", charp)

    node.run(nil).should == 10
  end

  it "raises Marlowe::TypeCheckFailed if the types don't match" do
    scope = Marlowe::Scope.root

    int = scope.type("int")
    sig =  Marlowe::TypeSignature.new int
    charp = scope.type("int8").pointer_to 
    sig << charp

    ext =  Marlowe::C::Function.new("atoi", sig)

    node = Marlowe::Nodes::StaticFunctionCall.new(ext)
    node << Marlowe::Nodes::IntegerLiteral.new(scope.type("int"), 10)

    lambda {
      node.run(nil)
    }.should raise_error(Marlowe::TypeCheckFailed)
  end

  it "can validate that the argument types" do
    scope = Marlowe::Scope.root

    int = scope.type("int")
    sig =  Marlowe::TypeSignature.new int
    charp = scope.type("int8").pointer_to 
    sig << charp

    ext =  Marlowe::C::Function.new("atoi", sig)

    node = Marlowe::Nodes::StaticFunctionCall.new(ext)
    node << Marlowe::Nodes::StringLiteral.new("10", charp)

    node.type_check.should be_true

    node = Marlowe::Nodes::StaticFunctionCall.new(ext)
    node << Marlowe::Nodes::IntegerLiteral.new(scope.type("int"), 10)

    node.type_check.should be_false
  end

  it "can invoke a Marlowe::Method when run" do
    scope = Marlowe::Scope.root

    sig =  Marlowe::TypeSignature.new scope.type("int")

    int = Marlowe::Nodes::IntegerLiteral.new(10, scope.type("int"))
    meth = Marlowe::Method.new "test", int, sig

    node = Marlowe::Nodes::StaticFunctionCall.new(meth)

    node.run(nil).value.should == 10
  end
end
