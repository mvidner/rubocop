# encoding: utf-8

module RuboCop
  module Cop
    module Lint
      # This cop checks for calls to debugger or pry.
      class Debugger < Cop
        MSG = 'Remove debugger entry point `%s`.'

        def_node_matcher :debugger_call?, <<-END
          {(send nil {:debugger :byebug} ...)
           (send (send nil :binding)
             {:pry :remote_pry :pry_remote} ...)
           (send (const nil :Pry) :rescue ...)
           (send nil {:save_and_open_page
                      :save_and_open_screenshot
                      :save_screenshot} ...)}
        END

        def_node_matcher :pry_rescue?, '(send (const nil :Pry) :rescue ...)'

        def on_send(node)
          return unless debugger_call?(node)
          add_offense(node, :expression, format(MSG, node.source))
        end

        def autocorrect(node)
          lambda do |corrector|
            if pry_rescue?(node)
              block = node.parent
              body  = block.children[2] # (block <send> <parameters> <body>)
              corrector.replace(block.source_range, body.source)
            else
              range = node.source_range
              range = range_with_surrounding_space(range, :left, nil, false)
              range = range_with_surrounding_space(range, :right, nil, true)
              corrector.remove(range)
            end
          end
        end
      end
    end
  end
end
