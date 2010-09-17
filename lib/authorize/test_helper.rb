require 'test/unit'
require 'authorize/graph/fixtures'

module Authorize
  module TestHelper
    # Assert that a given role explicitly has a given permission mode for a given resource
    # Example: assert_authorized(current_user, :read, :list, widget)
    # If a trustee is provided instead of a role, then the primary role of the trustee is used.
    def assert_authorized(*args)
      tor = args.shift
      role = tor.is_a?(Authorize::Role) ? tor : tor.role
      assert_block("Role #{role} is not authorized") {role.may?(*args)}
    end

    def assert_unauthorized(*args)
      tor = args.shift
      role = tor.is_a?(Authorize::Role) ? tor : tor.role
      assert_block("Role #{role} is authorized") {role.may_not?(*args)}
    end

    def assert_has_role(tor, subrole)
      role = tor.is_a?(Authorize::Role) ? tor : tor.role
      assert_block("Role #{role} does not include #{subrole}") {role.roles.include?(subrole)}
    end

    def assert_does_not_have_role(tor, subrole)
      role = tor.is_a?(Authorize::Role) ? tor : tor.role
      assert_block("Role #{role} includes #{subrole}") {!role.roles.include?(subrole)}
    end

    # A weak assertion of access
    # The assertion includes subordinate roles' permissions and considers global/class permissions
    def assert_permitted(tor, *args)
      role = tor.is_a?(Authorize::Role) ? tor : tor.role
      resource = args.pop
      request_mask = Authorize::Permission::Mask[*args]
      assert_block("Role #{role} is not permitted (#{request_mask})") do
        Authorize::Permission.over(resource).as(role.roles).permit?(request_mask)
      end
    end
  end
end