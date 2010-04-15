module Marlowe
  class Node < Treetop::Runtime::SyntaxNode
  end

  class If < Node
    def to_sexp
      b = [:body] + body.expressions.map { |x| x.to_sexp }

      sx = [:if, condition.to_sexp, b]

      return sx if then_body.empty?

      t = then_body.body.expressions.map { |x| x.to_sexp }

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

  class DefineMethod < Node
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
      [:method, name, singleton?, a, body]
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
      [:string, text_value]
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

  class ClassDeclaration < Node
    def name
      class_name.text_value
    end

    def declarations
      return [] if body.empty?
      body.declarations
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

    def scope_name
      scope.identifier.text_value
    end

    def identifier
      name.text_value
    end

    def display_name
      if scoped?
        "#{scope_name}::#{identifier}"
      else
        identifier
      end
    end

    def to_sexp
      [:typename, display_name]
    end
  end

  class TypedIdentifier < Node
    def name
      defn_name.text_value
    end
  end
end
