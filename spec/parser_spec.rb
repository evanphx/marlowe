require 'spec/helper'
require 'marlowe/parser'

describe Marlowe::Parser do

  def raw_parse(text)
    parser = Marlowe::Parser.new(text)
    parser.parse

    unless parser.successful?
      raise Marlowe::ParseError
    end

    return parser.to_sexp
  end

  def parse(text)
    parser = Marlowe::Parser.new(text)
    parser.parse

    unless parser.successful?
      puts
      parser.show_fixit
      raise Marlowe::ParseError
    end

    return parser.to_sexp
  end

  it "parses an empty class body" do
    txt  = <<-CODE
class Foo
end
    CODE

    parse(txt).should == [:marlowe, [:class, "Foo", [:body]]]
  end

  it "parses a type alias" do
    txt = <<-CODE
class Foo
  type A = Int
end
    CODE

    parse(txt).should == [:marlowe,
      [:class, "Foo",
        [:body,
          [:typealias, [:typename, "A"], [:typename, "Int"]]]]]
  end

  it "parses a type alias with a type instantiation" do
    txt = <<-CODE
class Foo
  type A = List[Int]
end
    CODE

    parse(txt).should == [:marlowe,
      [:class, "Foo",
        [:body,
          [:typealias, [:typename, "A"],
                       [:typeinst, [:typename, "List"],
                         [:typeparams, [:typename, "Int"]]]]]]]
  end

  it "parses an empty method definition" do
    txt = <<-CODE
class Foo
  def main
  end
end
    CODE

    parse(txt).should == [:marlowe,
      [:class, "Foo",
        [:body,
          [:method, "main", false, nil, [:body]]]]]
  end

  it "parses multiple methods" do
    txt = <<-CODE
class Foo
  def main
  end

  def b
  end
end

    CODE

    parse(txt).should == [:marlowe,
      [:class, "Foo",
        [:body,
          [:method, "main", false, nil, [:body]],
          [:method, "b", false, nil, [:body]]]]]
  end

  it "parses a method argument" do
    txt = <<-CODE
class Foo
  def main(argc: int)
  end
end
    CODE

    parse(txt).should == [:marlowe,
      [:class, "Foo", [:body,
        [:method, "main", false,
          [:decl_args, ["argc", "int"]],
          [:body]]]]]
  end

  it "parses many method arguments" do
    txt = <<-CODE
class Foo
  def main(argc: int, argv: int)
  end
end
    CODE

    parse(txt).should == [:marlowe,
      [:class, "Foo", [:body,
        [:method, "main", false,
          [:decl_args, ["argc", "int"], ["argv", "int"]],
          [:body]]]]]
  end

  it "parses a method argument of char**" do
    txt = <<-CODE
class Foo
  def main(argv: char**)
  end
end
    CODE

    parse(txt).should == [:marlowe,
      [:class, "Foo", [:body,
        [:method, "main", false,
          [:decl_args, ["argv", "char**"]],
          [:body]]]]]
  end

  it "parses a class with a type parameter" do
    txt = <<-CODE
class Foo[T]
end
    CODE

    parse(txt).should == [:marlowe,
      [:typeclass, "Foo",
        [:typeparams, [:typename, "T"]],
        [:body]]]
  end

  it "parses a class with a restricted type parameter" do
    txt = <<-CODE
class Foo[T: LessThan]
end
    CODE

    parse(txt).should == [:marlowe,
      [:typeclass, "Foo",
        [:typeparams, [:restype, "T", [:typename, "LessThan"]]],
        [:body]]]
  end

  it "parses a class with multiple type paramaters" do
    txt = <<-CODE
class Foo[T: LessThan, T2]
end
    CODE

    parse(txt).should == [:marlowe,
      [:typeclass, "Foo",
        [:typeparams,
          [:restype, "T", [:typename, "LessThan"]],
          [:typename, "T2"]], [:body]]]
  end

  it "parses accessing an ivar" do
    txt = <<-CODE
class Foo
  def main
    @total
  end
end
    CODE

    parse(txt).should == [:marlowe,
      [:class, "Foo", [:body,
        [:method, "main", false, nil, [:body,
          [:scoped_id, "@total"]]]]]]
  end

  it "parses a raw number" do
    txt = <<-CODE
class Foo
  def main
    42
  end
end
    CODE

    parse(txt).should == [:marlowe,
      [:class, "Foo", [:body,
        [:method, "main", false, nil, [:body,
          [:number, "42"]]]]]]

  end

  it "parses two expression in a def" do
    txt = <<-CODE
class Foo
  def main
    42
    47
  end
end
    CODE

    parse(txt).should == [:marlowe,
      [:class, "Foo", [:body,
        [:method, "main", false, nil, [:body,
          [:number, "42"],
          [:number, "47"]]]]]]

  end

  it "parses a double quoted string" do
    txt = <<-CODE
class Foo
  def main
    "this is text"
  end
end
    CODE

    parse(txt).should == [:marlowe,
      [:class, "Foo", [:body,
        [:method, "main", false, nil, [:body,
          [:string, "\"this is text\""]]]]]]

  end

  it "parses a single quoted string" do
    txt = <<-CODE
class Foo
  def main
    'this is text'
  end
end
    CODE

    parse(txt).should == [:marlowe,
      [:class, "Foo", [:body,
        [:method, "main", false, nil, [:body,
          [:string, "'this is text'"]]]]]]

  end

  it "parses an identifier" do
    txt = <<-CODE
class Foo
  def main
    argc
  end
end
    CODE

    parse(txt).should == [:marlowe,
      [:class, "Foo", [:body,
        [:method, "main", false, nil, [:body,
          [:id, "argc"]]]]]]

  end

  it "parses an identifier" do
    txt = <<-CODE
class Foo
  def main
    argc
  end
end
    CODE

    parse(txt).should == [:marlowe,
      [:class, "Foo", [:body,
        [:method, "main", false, nil, [:body,
          [:id, "argc"]]]]]]

  end

  it "parses a comparison" do
    txt = <<-CODE
class Foo
  def main
    1 == 3
  end
end
    CODE

    parse(txt).should == [:marlowe,
      [:class, "Foo", [:body,
        [:method, "main", false, nil, [:body,
          [:binop, "==",
            [:number, "1"],
            [:number, "3"]]]]]]]

  end

  it "parses a comparison right associative" do
    txt = <<-CODE
class Foo
  def main
    1 == 3 == 5
  end
end
    CODE

    parse(txt).should == [:marlowe,
      [:class, "Foo", [:body,
        [:method, "main", false, nil, [:body,
          [:binop, "==",
            [:number, "1"],
            [:binop, "==",
              [:number, "3"],
              [:number, "5"]]]]]]]]

  end

  it "parses an addition" do
    txt = <<-CODE
class Foo
  def main
    1 + 3
  end
end
    CODE

    parse(txt).should == [:marlowe,
      [:class, "Foo", [:body,
        [:method, "main", false, nil, [:body,
          [:binop, "+",
            [:number, "1"],
            [:number, "3"]]]]]]]

  end

  it "parses an addition right associative" do
    txt = <<-CODE
class Foo
  def main
    1 + 3 + 5
  end
end
    CODE

    parse(txt).should == [:marlowe,
      [:class, "Foo", [:body,
        [:method, "main", false, nil, [:body,
          [:binop, "+",
            [:number, "1"],
            [:binop, "+",
              [:number, "3"],
              [:number, "5"]]]]]]]]

  end

  it "parses an addition stronger than a comparison" do
    txt = <<-CODE
class Foo
  def main
    1 = 3 + 5
  end
end
    CODE

    parse(txt).should == [:marlowe,
      [:class, "Foo", [:body,
        [:method, "main", false, nil, [:body,
          [:binop, "=",
            [:number, "1"],
            [:binop, "+",
              [:number, "3"],
              [:number, "5"]]]]]]]]

    txt = <<-CODE
class Foo
  def main
    1 + 3 = 5
  end
end
    CODE

    parse(txt).should == [:marlowe,
      [:class, "Foo", [:body,
        [:method, "main", false, nil, [:body,
          [:binop, "=",
            [:binop, "+",
              [:number, "1"],
              [:number, "3"]],
            [:number, "5"]]]]]]]
  end

  it "parses a multitive" do
    txt = <<-CODE
class Foo
  def main
    1 * 3
  end
end
    CODE

    parse(txt).should == [:marlowe,
      [:class, "Foo", [:body,
        [:method, "main", false, nil, [:body,
          [:binop, "*",
            [:number, "1"],
            [:number, "3"]]]]]]]

  end

  it "parses an multitive stronger than a addition" do
    txt = <<-CODE
class Foo
  def main
    1 + 3 * 5
  end
end
    CODE

    parse(txt).should == [:marlowe,
      [:class, "Foo", [:body,
        [:method, "main", false, nil, [:body,
          [:binop, "+",
            [:number, "1"],
            [:binop, "*",
              [:number, "3"],
              [:number, "5"]]]]]]]]

    txt = <<-CODE
class Foo
  def main
    1 * 3 + 5
  end
end
    CODE

    parse(txt).should == [:marlowe,
      [:class, "Foo", [:body,
        [:method, "main", false, nil, [:body,
          [:binop, "+",
            [:binop, "*",
              [:number, "1"],
              [:number, "3"]],
            [:number, "5"]]]]]]]
  end

  it "parses a element access" do
    txt = <<-CODE
class Foo
  def main
    argv[1]
  end
end
    CODE

    parse(txt).should == [:marlowe,
      [:class, "Foo", [:body,
        [:method, "main", false, nil, [:body,
          [:aref,
            [:id, "argv"],
            [:number, "1"]]]]]]]
  end

  it "parses a element access of a function call" do
    txt = <<-CODE
class Foo
  def main
    c::thing()[1]
  end
end
    CODE

    parse(txt).should == [:marlowe,
      [:class, "Foo", [:body,
        [:method, "main", false, nil, [:body,
          [:aref,
            [:fcall, "c", "thing", [:args]],
            [:number, "1"]]]]]]]
  end

  it "parses a method call with parens" do
    txt = <<-CODE
class Foo
  def main
    argv.size(1)
  end
end
    CODE

    parse(txt).should == [:marlowe,
      [:class, "Foo", [:body,
        [:method, "main", false, nil, [:body,
          [:mcall,
            [:id, "argv"],
            "size",
            [:args,
              [:number, "1"]]]]]]]]
  end

  it "parses a method call with empty parens" do
    txt = <<-CODE
class Foo
  def main
    argv.size()
  end
end
    CODE

    parse(txt).should == [:marlowe,
      [:class, "Foo", [:body,
        [:method, "main", false, nil, [:body,
          [:mcall, [:id, "argv"], "size", [:args]]]]]]]
  end

  it "parses a method call chained to another method call" do
    txt = <<-CODE
class Foo
  def main
    argv.size().age()
  end
end
    CODE

    parse(txt).should == [:marlowe,
      [:class, "Foo", [:body,
        [:method, "main", false, nil, [:body,
          [:mcall,
            [:mcall, [:id, "argv"], "size", [:args]],
            "age",
            [:args]]]]]]]
  end

  it "parses a method call with no parens and no arguments" do
    txt = <<-CODE
class Foo
  def main
    argv.size
  end
end
    CODE

    parse(txt).should == [:marlowe,
      [:class, "Foo", [:body,
        [:method, "main", false, nil, [:body,
          [:mcall, [:id, "argv"], "size", [:args]]]]]]]
  end

  it "parses a method call with no parens and arguments" do
    txt = <<-CODE
class Foo
  def main
    argv.size 1
  end
end
    CODE

    parse(txt).should == [:marlowe,
      [:class, "Foo", [:body,
        [:method, "main", false, nil, [:body,
          [:mcall, [:id, "argv"], "size",
            [:args, [:number, "1"]]]]]]]]
  end

  it "parses a method call chained with no parens and arguments" do
    txt = <<-CODE
class Foo
  def main
    argv.size.add 1
  end
end
    CODE

    parse(txt).should == [:marlowe,
      [:class, "Foo", [:body,
        [:method, "main", false, nil, [:body,
          [:mcall, [:id, "argv"], "size",
            [:args, [:number, "1"]]]]]]]]
  end

  it "does not parse method calls with no parens used in arguments" do
    txt = <<-CODE
class Foo
  def main
    argv.size argv.add 1
  end
end
    CODE

    lambda {
      raw_parse(txt)
    }.should raise_error(Marlowe::ParseError)
  end

  it "parses method calls used as arguments to method calls" do
    txt = <<-CODE
class Foo
  def main
    argv.size(r1.m1, r2.m2())
  end
end
    CODE

    parse(txt).should == [:marlowe,
      [:class, "Foo", [:body,
        [:method, "main", false, nil, [:body,
          [:mcall, [:id, "argv"], "size", [:args,
              [:mcall, [:id, "r1"], "m1", [:args]],
              [:mcall, [:id, "r2"], "m2", [:args]]]]]]]]]
  end

  it "parses method calls used as arguments to method calls (no parens)" do
    txt = <<-CODE
class Foo
  def main
    argv.size(r1.m1 1, r2.m2())
  end
end
    CODE

    parse(txt).should == [:marlowe,
      [:class, "Foo", [:body,
        [:method, "main", false, nil, [:body,
          [:mcall, [:id, "argv"], "size", [:args,
              [:mcall, [:id, "r1"], "m1", [:args,
                [:number, "1"],
                [:mcall, [:id, "r2"], "m2", [:args]]]]]]]]]]]
  end

  it "parses an 'if'" do
    txt = <<-CODE
class Foo
  def main
    if argv
      argv.size
    end
  end
end
    CODE

    parse(txt).should == [:marlowe,
      [:class, "Foo", [:body,
        [:method, "main", false, nil, [:body,
          [:if, [:id, "argv"], [:body,
            [:mcall,
              [:id, "argv"], "size", [:args]]]]]]]]]
  end

  it "parses an 'if' with multiple expressions in the body" do
    txt = <<-CODE
class Foo
  def main
    if argv
      10
      11
    end
  end
end
    CODE

    parse(txt).should == [:marlowe,
      [:class, "Foo", [:body,
        [:method, "main", false, nil, [:body,
          [:if, [:id, "argv"], [:body,
            [:number, "10"],
            [:number, "11"]]]]]]]]
  end

  it "parses an 'if' with a 'then'" do
    txt = <<-CODE
class Foo
  def main
    if argv
      argv.size
    then
      18
    end
  end
end
    CODE

    parse(txt).should == [:marlowe,
      [:class, "Foo", [:body,
        [:method, "main", false, nil, [:body,
          [:if, [:id, "argv"],
            [:body,
              [:mcall,
                [:id, "argv"], "size", [:args]]],
            [:body,
              [:number, "18"]]]]]]]]
  end

end
