module ApexParser
  module AST
    class CommentNode < SingleValueNode
      def accept(visitor, local_scope)
        nil
      end
    end
  end
end
