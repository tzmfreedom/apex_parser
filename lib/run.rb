require './lib/apex'
require './lib/visitor'
require './lib/statement'
require 'json'

require 'bundler'

Bundler.require

parser = ApexCompiler.new

interpreter = InterpreterVisitor.new
Dir['./lib/*.cls'].each do |filepath|
  class_node = parser.scan_str(File.read(filepath))
  class_node.accept(interpreter)
end
call_method_node = CallMethodNode.new(
  receiver: IdentifyNode.new(name: :Hoge),
  arguments: [],
  apex_method_name: IdentifyNode.new(name: :action)
)
call_method_node.accept(interpreter, {})
