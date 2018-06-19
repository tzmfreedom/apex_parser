require './lib/apex'

parser = ApexCompiler.new

class_def = parser.scan_str(STDIN.read)
ApexClassTable.register(class_def.name, class_def)
class_def.call(:action, [], {})

# statements.each do |statement|
#   pp statement
# end
