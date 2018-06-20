require './lib/apex'
require './lib/statement'
require './lib/node'
require './lib/visitor'

parser = ApexCompiler.new

interpreter = InterpreterVisitor.new
class_node = parser.scan_str(STDIN.read)
class_node.accept(interpreter)

call_class_method_node = CallStaticMethodNode.new(
  apex_class_name: class_node.name,
  arguments: [],
  apex_method_name: :action
)
call_class_method_node.accept(interpreter, {})
