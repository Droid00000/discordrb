# frozen_string_literal: true

# Discordrb and all its functionality, in this case only the {.predicate_method} method.
module Discordrb
  # Define a predicate method on a class. This is similar to `attr_reader`, except the instance variable is
  #   exposed via a predicate method, e.g. `#pinned?` for `@pinned`.
  # @param target [Class] The class where the predicate method should be defined.
  # @param name [String, Symbol] The name of the attribute. A `?` will be added if it isn't already present.
  # @return [Symbol] The name of the method that was created.
  def self.predicate_method(target, name)
    name = name.to_s.delete('?')
    target.attr_reader(name)
    target.alias_method("#{name}?", name)
    target.remove_method(name)
    :"#{name}?"
  end
end
