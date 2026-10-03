require "test_helper"

class MembershipTest < ActiveSupport::TestCase
  test "the last admin can't leave while others remain" do
    group = Group.create_with_admin!(users(:one), name: "Family")
    group.memberships.create!(user: users(:two))
    admin = group.memberships.find_by(user: users(:one))

    assert_not admin.destroy
    assert_match(/at least one admin/, admin.errors.full_messages.first)
  end
end
