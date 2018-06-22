require './lib/apex'
require './lib/visitor'
require './lib/statement'
require 'json'

require 'bundler'

Bundler.require

parser = ApexCompiler.new

interpreter = InterpreterVisitor.new
class_node = parser.scan_str(File.read('./lib/sample.cls'))
class_node.accept(interpreter)

call_method_node = CallMethodNode.new(
  receiver: class_node.name,
  arguments: [],
  apex_method_name: IdentifyNode.new(name: :action)
)
call_method_node.accept(interpreter, {})
