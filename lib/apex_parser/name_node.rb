def field_from_name(node, local_scope)
  names = node.name
  name = names.first

  # variable.field...field
  variable = local_scope[name]
  receiver = names[1..-1].reduce(variable) do |receiver, name|
    break nil if receiver.nil?
    receiver.fields[name]
  end
  return receiver unless receiver.nil?

  # this_field.field...field
  field = local_scope[:this].fields[name]
  receiver = names[1..-1].reduce(field) do |receiver, name|
    break nil if receiver.nil?
    receiver.fields[name]
  end
  return receiver unless receiver.nil?

  # class.static_field...field
  if names.length > 1
    apex_class = ApexClassTable[name]
    static_method_name = names[1]
    static_method = apex_class.static_fields[static_method_name]
    receiver = names[1..-1].reduce(static_method) do |receiver, name|
      break nil if receiver.nil?
      receiver.fields[name]
    end
    return receiver unless receiver.nil?
  end

  # name_space.class.static_field...field
  if names.length > 2
    namespace = NameSpaceTable[name]
    apex_class_name = names[1]
    apex_class = namespace[apex_class_name]
    static_method = names[2]
    receiver = names[2..-1].reduce(apex_class[static_method]) do |receiver, name|
      break nil if receiver.nil?
      receiver.fields[name]
    end
    return receiver unless receiver.nil?
  end
end

def receiver_from_name(node, local_scope)
  names = node.name
  name = names.first
  method_name = node.method_name

  # variable.field.field...method()
  variable = local_scope[name]
  receiver = names[1..-1].reduce(variable) do |receiver, name|
    break nil if receiver.nil?
    receiver.fields[name]
  end

  unless !(receiver.nil?) && receiver.methods[method_name]
    return receiver
  end

  # this_field.field.field...method()
  field = local_scope[:this].fields[name]
  receiver = names[1..-1].reduce(field) do |receiver, name|
    break nil if receiver.nil?
    receiver.fields[name]
  end

  unless !(receiver.nil?) && receiver.methods[method_name]
    return receiver
  end

  # class.static_field.static_method()
  if names.length == 2
    apex_class = ApexClassTable[name]
    apex_class.static_fields[names[1]]
    unless receiver.nil? && apex_class.methods[method_name]
      return receiver
    end
  end

  # class.static_field.field...method()
  if names.length >= 3
    apex_class = ApexClassTable[name]
    static_method = names[1]
    static_field = apex_class.static_fields[static_method]
    receiver = names[2..-1].reduce(static_field) do |receiver, name|
      break nil if receiver.nil?
      receiver.fields[name]
    end
    unless receiver.nil? && apex_class.methods[method_name]
      return receiver
    end
  end

  # namespace.class.static_field.field....method()
  if names.length >= 3
    namespace = NameSpaceTable[name]
    class_name = names[1]
    apex_class = namespace.classes[class_name]
    static_method_name = apex_class[names[2]]
    receiver = names[2..-1].reduce(static_method_name) do |receiver, name|
      break nil if receiver.nil?
      receiver.fields[name]
    end
    unless receiver.nil? && apex_class.methods[method_name]
      return receiver
    end
  end
end
