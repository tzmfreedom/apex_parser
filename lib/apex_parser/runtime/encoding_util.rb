require 'base64'

module ApexParser
  ApexClassCreator.new do |c|
    c.add_class(:EncodingUtil, %i[public])

    c.add_static_method(:base64Decode, [:public], :String, [[:String, :input_string]]) do |local_scope|
      decoded_string = Base64.decode64(local_scope[:input_string].value)
      AST::Blob.new(value: decoded_string)
    end

    c.add_static_method(:base64Encode, [:public], :String, [[:Blob, :input_blob]]) do |local_scope|
      decoded_string = Base64.encode64(local_scope[:input_blob].value)
      AST::ApexStringNode.new(value: decoded_string)
    end
  end
end
