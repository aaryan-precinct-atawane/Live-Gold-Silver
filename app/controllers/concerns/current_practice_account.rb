# Finds this browser's practice account, creating one on the first visit.
# The account's random token is kept in a signed (tamper-proof) permanent cookie.
module CurrentPracticeAccount
  extend ActiveSupport::Concern

  COOKIE = :practice_account_token

  private

  def current_practice_account
    @current_practice_account ||= find_practice_account || create_practice_account
  end

  def find_practice_account
    token = cookies.signed[COOKIE]
    PracticeAccount.find_by(token: token) if token.present?
  end

  def create_practice_account
    PracticeAccount.create!.tap do |account|
      cookies.signed.permanent[COOKIE] = { value: account.token, httponly: true, same_site: :lax }
    end
  end

  # Closes any of this account's trades that have expired or been stopped out.
  # `prices` is { "gold" => usd, "silver" => usd }; metals with no price are skipped.
  def settle_due_trades(prices)
    current_practice_account.practice_trades.active.find_each do |trade|
      price = prices[trade.metal]
      trade.settle_if_due!(price) if price
    end
  end
end
