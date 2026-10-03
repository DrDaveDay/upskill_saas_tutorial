require "test_helper"

class FlowTest < ActionDispatch::IntegrationTest
  test "sign up, create a group, set a prize, invite, paste scores, see the leaderboard" do
    post registration_path, params: { user: { name: "Carol", email_address: "carol@example.com", password: "secret123", password_confirmation: "secret123" } }
    assert_redirected_to root_path

    post groups_path, params: { group: { name: "The Smiths" } }
    group = Group.last
    assert_redirected_to edit_group_path(group)
    assert group.admin?(User.find_by(email_address: "carol@example.com"))

    patch group_prize_path(group), params: { prize: { month: Date.current.iso8601, description: "Winner picks the pizza" } }
    assert_equal "Winner picks the pizza", group.prize_for(Date.current).description

    post results_path, params: { share_text: "Wordle 1,567 2/6\n\n🟩🟩🟩🟩🟩", played_on: Date.current.iso8601 }
    assert_redirected_to root_path
    follow_redirect!
    assert_match "Saved Wordle 2/6 (+5)", response.body

    # A second person joins with the invite link.
    delete session_path
    get invitation_path(group.invite_code)
    assert_response :success
    post registration_path, params: { user: { name: "Dan", email_address: "dan@example.com", password: "secret123", password_confirmation: "secret123" } }
    assert_redirected_to invitation_url(group.invite_code)
    post invitation_path(group.invite_code)
    assert_redirected_to group_path(group)

    post manual_results_path, params: { result: { game: "connections", played_on: Date.current.iso8601, solved: "1", score_value: "0" } }
    assert_equal 6, User.find_by(name: "Dan").results.sole.points

    get group_path(group)
    assert_response :success
    assert_match "Winner picks the pizza", response.body
    assert_match "Dan is leading", response.body
  end

  test "non-admins can't set the prize" do
    group = Group.create_with_admin!(users(:one), name: "Office")
    group.memberships.create!(user: users(:two))
    sign_in_as users(:two)

    patch group_prize_path(group), params: { prize: { month: Date.current.iso8601, description: "Free lunch" } }
    assert_redirected_to group_path(group)
    assert_nil group.prize_for(Date.current)
  end

  test "can't view groups you're not in" do
    group = Group.create_with_admin!(users(:one), name: "Office")
    sign_in_as users(:two)
    get group_path(group)
    assert_response :not_found
  end

  test "unrecognised paste re-renders with an error" do
    sign_in_as users(:one)
    post results_path, params: { share_text: "hello", played_on: Date.current.iso8601 }
    assert_response :unprocessable_entity
    assert_match "couldn&#39;t find", response.body
  end
end
