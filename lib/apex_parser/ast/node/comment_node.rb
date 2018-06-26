module ApexParser
  module AST
    class CommentNode < SingleValueNode
      def accept(visitor)
        nil
      end
    end
  end
end
