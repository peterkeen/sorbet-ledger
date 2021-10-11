require_relative '../lib/sorbet-ledger'
require 'tmpdir'
require 'securerandom'

def log(msg)
  STDERR.puts "#{Time.now} #{msg}"
end

NUM_TRANSACTIONS = 100000

accounts = (0..100).map { |_| SorbetLedger::Account.new(name: SecureRandom.hex(8)) }
ledger = SorbetLedger::Ledger.new

log("start_gen")
now = Time.now.utc.to_i
(0..NUM_TRANSACTIONS).each do |i|
  amount = rand(10000)
  source_account = accounts[rand(accounts.length - 1)]
  sink_account = accounts[rand(accounts.length - 1)]

  ledger.transactions << SorbetLedger::Transaction.new(
    note: "transfer from #{source_account.name} to #{sink_account.name}",
    timestamp: now - i,
    entries: [
      SorbetLedger::JournalEntry.new(account: source_account, currency: 'usd', amount: amount * -1),
      SorbetLedger::JournalEntry.new(account: sink_account, currency: 'usd', amount: amount),      
    ]
  )
end
log("end_gen")

dir = Dir.mktmpdir
log("start_save dir=#{dir}")
ledger.save_to_path(dir)
log("end_save")

log("start_load")
new_ledger = SorbetLedger::Ledger.from_path(dir)
log("end_load")

log("start_balances")
new_ledger.balances
log("end_balances")
