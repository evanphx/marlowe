require 'rubygems'

require 'marlowe/parser'
require 'marlowe/nodes'
require 'marlowe/c'
require 'marlowe/gen'

require 'optparse'
require 'ostruct'
require 'pp'

options = OpenStruct.new

o = OptionParser.new do |opts|
  opts.banner = "Usage: marlowe [options] file.mrl"

  opts.on("-x", "--xml") do |v|
    options.xml = v
  end

  opts.on("-g", "--gen") do |v|
    options.gen = v
  end

  opts.on("-s", "--sexp") do |v|
    options.sexp = v
  end
end

o.parse!

unless file = ARGV.shift
  puts "Please specify a file"
end

txt = File.read(file)

parser = Marlowe::Parser.new(txt)

def generate(tree)
  tree.classes.each do |top|
    top.declarations.each do |decl|
      decl.container = top

      cres = Marlowe::CResolver.new
      cres.add_file "/usr/include/stdio.h"

      b = Marlowe::Binding.new
      g = Marlowe::GenerationState.new(cres, b)

      args = []
      if ao = decl.arguments
        ao.args.each do |ti|
          if ti.type_name.scope_name == "c"
            type = g.find_c_type(ti.type_name.identifier)
          else
            raise "sorry"
          end

          b.add_binding ti.name, type
          args << "#{type.to_c(g)} #{ti.name}"
        end
      end

      body = ""
      return_type = nil
      decl.expressions.each do |ex|
        return_type = ex.type(g)
        body << "  #{ex.to_c(g)};\n"
      end

      if return_type
        puts "\#include \"stdio.h\""
        puts "#{return_type.to_c(g)} #{decl.c_name(g)}(#{args.join(', ')}) {"
        puts body
        puts "}"
      end
    end
  end

  puts "int main(int argc, char** argv) { _Foo_s_main(argc, argv); }"
end

parser.parse
if parser.successful?
  generate(tree) if options.gen
  parser.to_xml(STDOUT) if options.xml
  pp parser.to_sexp if options.sexp
else
  puts "Parse error:"
  parser.show_fixit
end

