module Marlowe
  class Node < Treetop::Runtime::SyntaxNode
  end

  class If < Node
    def to_sexp
      b = [:body] + body.expressions.map { |x| x.to_sexp }

      sx = [:if, condition.to_sexp, b]

      return sx if else_body.empty?

      t = else_body.body.expressions.map { |x| x.to_sexp }

      sx << ([:body] + t)

      return sx
    end
  end

  class While < Node
    def to_sexp
      b = [:body] + body.expressions.map { |x| x.to_sexp }

      return [:while, condition.to_sexp, b]
    end
  end

  class Until < Node
    def to_sexp
      b = [:body] + body.expressions.map { |x| x.to_sexp }

      return [:until, condition.to_sexp, b]
    end
  end

  class ImportDeclaration < Node
    def to_sexp
      [:import, package_name.text_value]
    end

    def local_name
      package_name.start.text_value
    end

    def pieces
      [package_name.start.text_value] +
        package_name.rest.elements.map { |x| x.part.text_value }
    end

    def declare(c, file)
      what = pieces
      tree = c.import(what)

      # Detect importing a package
      if tree.package == what.join(".")
        file.scope[what.last] = tree.package
      elsif obj = tree.find(what.last)
        file.scope[what.last] = obj
      else
        raise "Unable to import: #{what.join('.')}"
      end
    end
  end

  class Annotation < Node
    def to_sexp
      head = [:annotation, name.text_value]
      unless args.empty?
        args.list.annotations.each do |x|
          case x
          when AnnotationNamedValue
            head << [x.name, x.value]
          else
            head << x.value
          end
        end
      end

      head
    end
  end

  class AnnotationNamedValue < Node
    def value
      annotation_const_value.value
    end

    def name
      identifier.text_value
    end
  end

  module Annotated
    def annotations
      if annos.empty?
        []
      else
        annos.elements
      end
    end
  end

  class VarDecl < Node
    include Annotated

    def name
      @name ||= identifier.text_value
    end

    def to_sexp
      if type.empty?
        [:infered_var, name, expression.to_sexp]
      else
        [:typed_var, name, type.local_var_type.named_type.to_sexp,
          expression.to_sexp]
      end
    end

    def run(c)
      frame = c.current_callframe

      et = expression.value_type(c)

      if frame.local?(name)
        raise "Local variable #{name} already defined"
      end

      val = expression.run(c)

      frame.set_local name, et, val

      return val
    end
  end

  class IVarDecl < Node
    include Annotated

    def name
      scoped_identifier.text_value
    end

    def declare(cls, file)
      cls.add_ivar(name, named_type.extract_type(c))
    end

    def to_sexp
      a = annotations.map { |x| x.to_sexp }
      [:ivar_decl, name, named_type.to_sexp, a]
    end
  end

  class AliasDeclaration < Node
    def to_sexp
      [:alias, type.text_value, exttype.text_value]
    end

    def declare(c, cls)
    end
  end

  class FromDeclaration < Node
    def file_path
      path.string.text_value
    end

    def declarations
      return [] if body.empty?
      body.declarations
    end
  end

  class BindMethod < Node
    def singleton?
      !single.text_value.empty?
    end

    def method_name
      if as_name.empty?
        func_name
      else
        as_name.name.text_value
      end
    end

    def func_name
      name.text_value
    end

    def arguments
      return nil if args.empty?
      return args
    end

    def declare(int, file)
      types = arguments.args.map { |x| x.extract_type(int) }
      ret_type = rettype.extract_type(int)

      if singleton?
        cls.bind_foreign_singleton_method(method_name, func_name, types, ret_type)
      else
        cls.bind_foreign_method(method_name, func_name, types, ret_type)
      end
    end

    def to_sexp
      [:bind, singleton?, func_name, arguments.to_sexp]
    end
  end

  class DefineMethod < Node
    include Annotated

    attr_accessor :container

    def singleton?
      !single.text_value.empty?
    end

    def name
      defn_name.text_value
    end

    def arguments
      return nil if args.empty?
      return args
    end

    def expressions
      return [] if body.empty?
      body.expressions
    end

    def c_name(g)
      if singleton?
        "_#{container.name}_s_#{name}"
      else
        "_#{container.name}_i_#{name}"
      end
    end

    def to_xml(io)
      io.puts "<method name=\"#{name}\" singleton=\"#{singleton?.inspect}\">"
      if arg = arguments
        arg.to_xml(io)
      end

      io.puts "<body>"
      expressions.each do |x|
        x.to_xml(io)
      end
      io.puts "</body>"

      io.puts "</method>"
    end

    def to_sexp
      if arguments
        a = args.to_sexp
      else
        a = nil
      end
      body = expressions.map { |x| x.to_sexp }
      body.unshift :body

      an = annotations.map { |x| x.to_sexp }
      [:method, name, singleton?, a, body, an]
    end

    def declare(cls, file)
      if singleton?
        m = cls.new_singleton_method(name)
      else
        m = cls.new_method(name)
      end

      m.arguments = arguments
      m.body = expressions
    end
  end

  class QuotedString < Node
    def to_c(g)
      text_value
    end

    def to_xml(io)
      io.puts "<string>"
      io.puts text_value
      io.puts "</string>"
    end

    def to_sexp
      [:string, string.text_value]
    end

    def interp_type(c)
      c.find_type(:string)
    end

    def run(c)
      @data ||= c.new_string(string.text_value)
    end

    def value_type(c)
      str_class = c.import(["marlowe", "String"])
      p str_class
    end

    def value
      string.text_value
    end
  end

  class Number < Node
    def to_c(g)
      text_value
    end

    def to_xml(io)
      io.puts "<number value=\"#{text_value}\"/>"
    end

    def to_sexp
      [:number, text_value]
    end

    def interp_type(c)
      c.int32
    end

    def run(c)
      text_value.to_i
    end

    def value
      text_value.to_i
    end
  end

  class Identifier < Node
    def to_c(g)
      text_value
    end

    def to_xml(io)
      io.puts "<identifier name=\"#{text_value}\"/>"
    end

    def to_sexp
      [:id, text_value]
    end
  end

  class ScopedIdentifier < Node
    def to_sexp
      [:scoped_id, text_value]
    end
  end

  class FunctionCall < Node
    def to_c(g)
    end

    def name
      identifier.text_value
    end

    def to_sexp
      [:call, name, params.to_sexp]
    end

    def run(c)
      m = c.lookup_method(name)
      m.run(c, params.expressions)
    end

    def resolve(meth)
      meth.scope.find(name)
    end
  end

  class CallParams < Node
    def expressions
      [expression] + more.elements.map {|elt| elt.expression}
    end

    def to_sexp
      [:args] + expressions.map { |x| x.to_sexp }
    end
  end

  class ScopedFunctionCall < Node
    def scope_identifier
      function_scope.identifier.text_value
    end

    def c_func(g)
      @c_func ||= g.find_c_function(function_call.name)
    end

    def func_name
      function_call.name
    end

    def type(g)
      if scope_identifier == "c"
        if func = c_func(g)
          return g.find_c_type(func.return_type)
        end
      end

      raise "unknown type"
    end

    def arguments
      return [] if function_call.params.empty?
      function_call.params.expressions
    end

    def to_c(g)
      if scope_identifier == "c"
        if func = c_func(g)
          args = arguments.map { |e| e.to_c(g) }
          return "#{func_name}(#{args.join(', ')})"
        end
      end
      raise "ug"
    end

    def to_xml(io)
      io.puts "<function_call scope=\"#{scope_identifier}\" name=\"#{func_name}\">"
      arguments.each_with_index do |arg, index|
        io.puts "<argument index=\"#{index}\">"
        arg.to_xml(io)
        io.puts "</argument>"
      end
      io.puts "</function_call>"
    end

    def to_sexp
      args = [:args] + arguments.map { |x| x.to_sexp }
      [:fcall, scope_identifier, func_name, args]
    end

    def run(c)
      if scope_identifier == "foreign"
        func = c.find_foreign(func_name)
        func.run(c, arguments)
      else
        raise "unable to handle"
      end
    end
  end

  class MethodCall < Node
    def name
      apply.name.text_value
    end

    def to_sexp
      if apply.arguments.empty?
        args = [:args]
      else
        args = apply.arguments.to_sexp
      end

      outer = [:mcall, recv.to_sexp, name, args]
      return outer if chaining.empty?

      current = outer
      chaining.elements.each do |ap|
        if ap.arguments.empty?
          sub_args = [:args]
        else
          sub_args = ap.arguments.to_sexp
        end

        current = [:mcall, current, ap.name.text_value, sub_args]
      end

      return current
    end
  end

  class MethodCallNoParen < MethodCall
    def to_sexp
      current = [:mcall, recv.to_sexp, name, [:args]]
      return current if chaining.empty?

      chaining.elements.each do |ap|
        current = [:mcall, current, ap.name.text_value, [:args]]
      end

      return current
    end
  end

  class MethodCallNPArgs < MethodCallNoParen
    def to_sexp
      [:mcall, recv.to_sexp, name, arguments.to_sexp]
    end
  end

  class ArefOperator < Node
    def to_c(g)
      "#{recv.to_c(g)}[#{index.to_c(g)}]"
    end

    def to_xml(io)
      io.puts "<element_access>"

      io.puts "<receiver>"
      recv.to_xml(io)
      io.puts "</receiver>"

      io.puts "<index>"
      index.to_xml(io)
      io.puts "</index>"

      io.puts "</element_access>"
    end

    def to_sexp
      [:aref, recv.to_sexp, index.to_sexp]
    end
  end

  class BinaryOperation < Node
    def to_c(g)
      "(#{lhs.to_c(g)} #{operator.text_value} #{rhs.to_c(g)})"
    end

    def to_xml(io)
      io.puts "<binary_operation operator=\"#{operator.text_value}\">"
      lhs.to_xml(io)
      rhs.to_xml(io)
      io.puts "</binary_operation>"
    end

    def to_sexp
      [:binop, operator.text_value, lhs.to_sexp, rhs.to_sexp]
    end
  end

  class ComparisonOperation < BinaryOperation
  end

  class AdditiveOperation < BinaryOperation
  end

  class MultitiveOperation < BinaryOperation
  end

  class PackageDeclaration < Node
    def name
      package_name.text_value
    end

    def to_sexp
      [:package, package_name.text_value]
    end

    def declare(c, file)
      file.package = package_name.text_value
    end
  end

  class ClassDeclaration < Node
    def name
      class_name.text_value
    end

    def declarations
      return [] if body.empty?
      body.declarations
    end

    def declared_methods
      declarations.select { |x| x.kind_of? DefineMethod }
    end

    def type_params
      tp = _type_params
      return nil unless tp.kind_of? TypeParams
      return tp.type_params
    end

    def type_class?
      _type_params.kind_of? TypeParams
    end

    def to_xml(io)
      io.puts "<class name=\"#{name}\">"
      declarations.each do |decl|
        decl.to_xml(io)
      end
      io.puts "</class>"
    end

    def to_sexp
      decls = declarations.map { |x| x.to_sexp }
      decls.unshift :body

      if type_class?
        tp = [:typeparams] + type_params.map { |x| x.to_sexp }
        [:typeclass, name, tp, decls]
      else
        [:class, name, decls]
      end
    end

    def declare(c, file)
      if type_class?
        cls = TypeClass.new(name)
        cls.type_params = type_params.map { |x| x.declare(c, file) }
      else
        cls = Class.new(name)
      end

      declarations.each { |x| x.declare(cls, file) }
    end
  end

  class TypeParams < Node
    def type_params
      [type_param] + more.elements.map { |x| x.type_param }
    end

    def to_sexp
      [:typeparams] + type_params.map { |x| x.to_sexp }
    end
  end

  class RestrictedType < Node
    def name
      class_name.text_value
    end

    def to_sexp
      [:restype, name, type_name.to_sexp]
    end
  end

  class Arguments < Node
    def args
      defn_arg_list.declarations
    end

    def to_xml(io)
      args.each do |arg|
        io.puts "<argument name=\"#{arg.name}\" type=\"#{arg.type_name.display_name}\"/>"
      end
    end

    def to_sexp
      all = args.map do |x|
        [x.name, x.type_name.display_name]
      end

      [:decl_args] + all
    end
  end

  class TypeInstantiate < Node
    def to_sexp
      [:typeinst, type_name.to_sexp, type_params.to_sexp]
    end
  end

  class TypeAlias < Node
    def to_sexp
      [:typealias, type_name.to_sexp, named_type.to_sexp]
    end
  end

  class TypeName < Node

    def scoped?
      !scope.empty?
    end

    def scope_elements
      scope.elements.map { |x| x.identifier.text_value }
    end

    def scope_name
      scope_elements.join(".")
    end

    def identifier
      name.text_value
    end

    def display_name
      if scoped?
        "#{scope_name}.#{identifier}#{suffix.text_value}"
      else
        "#{identifier}#{suffix.text_value}"
      end
    end

    def to_sexp
      [:typename, display_name]
    end

    def extract_type(c)
      scope = self.scope
      name = self.name.text_value

      path = scope.text_value.split(".")

      pkg = c.find_package(path)

      type = pkg.find_type(name)

      suffix.text_value.split(//).each do |s|
        case s
        when "*"
          type = type.pointer_to
        else
          raise "Unknown suffix: #{s}"
        end
      end

      type
    end
  end

  class TypedIdentifier < Node
    def name
      defn_name.text_value
    end

    def extract_type(c)
      scope = type_name.scope
      name = type_name.name.text_value

      path = scope.text_value.split(".")

      p path

      pkg = c.find_package(path)

      type = pkg.find_type(name)

      type_name.suffix.text_value.split(//).each do |s|
        case s
        when "*"
          type = type.pointer_to
        else
          raise "Unknown suffix: #{s}"
        end
      end

      type
    end
  end
end
