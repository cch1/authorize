require 'test/unit'

module Authorize
  module TestHelper
    include Redis::Fixtures

    # Assert that a given role explicitly has a given permission mode over a given resource
    # Example: assert_authorized(current_user, :read, :list, widget)
    # If a trustee is provided instead of a role, then the primary role of the trustee is used.
    def assert_permitted(*args)
      tor = args.shift
      role = tor.is_a?(Authorize::Role) ? tor : tor.role
      assert_block("Role #{role} is not authorized") {role.can?(*args)}
    end

    def assert_not_permitted(*args)
      tor = args.shift
      role = tor.is_a?(Authorize::Role) ? tor : tor.role
      assert_block("Role #{role} is authorized") {!role.can?(*args)}
    end
  end
end