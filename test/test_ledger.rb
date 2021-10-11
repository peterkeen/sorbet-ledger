require_relative '../lib/sorbet-ledger'
require 'minitest/autorun'

class TestLedger < Minitest::Test
  def test_balances
    ledger = SorbetLedger::Ledger.new
    checking = SorbetLedger::Account.new(name: 'Assets:Checking')
    expense = SorbetLedger::Account.new(name: 'Expenses:Whatever')

    ledger.transactions << SorbetLedger::Transaction.new(
      note: 'Some expense',
      timestamp: Time.now.utc.to_i,
      entries: [
        SorbetLedger::JournalEntry.new(account: expense, currency: 'usd', amount: 100),
        SorbetLedger::JournalEntry.new(account: checking, currency: 'usd', amount: -100)
      ]
    )

    ledger.transactions << SorbetLedger::Transaction.new(
      note: 'Some expense',
      timestamp: Time.now.utc.to_i + 1,
      entries: [
        SorbetLedger::JournalEntry.new(account: expense, currency: 'usd', amount: 100),
        SorbetLedger::JournalEntry.new(account: checking, currency: 'usd', amount: -100)
      ]
    )

    assert_equal({'Expenses:Whatever' => {'usd' => 200}, 'Assets:Checking' => {'usd' => -200}}, ledger.balances)
  end
end
