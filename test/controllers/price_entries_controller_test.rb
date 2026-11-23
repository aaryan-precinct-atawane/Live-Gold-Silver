require "test_helper"

class PriceEntriesControllerTest < ActionDispatch::IntegrationTest
  test "lists entries for both metals" do
    get price_entries_path
    assert_response :success
    assert_select "#entries_gold li", 1
    assert_select "#entries_silver li", 1
  end

  test "adds a valid entry" do
    assert_difference -> { PriceEntry.count }, 1 do
      post price_entries_path, params: { price_entry: { metal: "gold", price_inr: "77000", price_usd: "2670.5" } }
    end
    assert_redirected_to price_entries_path(metal: "gold")
    follow_redirect!
    assert_select ".flash--notice", "Gold price added."
  end

  test "shows errors for an invalid entry" do
    assert_no_difference -> { PriceEntry.count } do
      post price_entries_path, params: { price_entry: { metal: "gold", price_inr: "0", price_usd: "" } }
    end
    assert_response :unprocessable_entity
    assert_select ".errors li", minimum: 1
  end

  test "rejects a request without price_entry params" do
    post price_entries_path, params: {}
    assert_response :bad_request
  end

  test "removes an entry" do
    assert_difference -> { PriceEntry.count }, -1 do
      delete price_entry_path(price_entries(:gold_low))
    end
    assert_redirected_to price_entries_path
  end
end
