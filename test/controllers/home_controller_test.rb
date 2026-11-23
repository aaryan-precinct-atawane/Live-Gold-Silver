require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "homepage links to the live prices" do
    get root_path
    assert_response :success
    assert_select "h1", /Gold & Silver prices/
    assert_select "a[href=?]", prices_path, text: "View live prices"
  end

  test "homepage has no link to manage prices" do
    get root_path
    assert_select "a[href=?]", price_entries_path, 0
  end

  test "other pages still link to manage prices" do
    get prices_path
    assert_select "a[href=?]", price_entries_path, text: "Manage prices"
  end
end
