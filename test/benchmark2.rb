require_relative '../lib/sorbet-ledger'
require 'pp'

def log(msg)
  STDERR.puts "#{Time.now} #{msg}"
end

log("start_load")
ledger = SorbetLedger::Ledger.from_path(ARGV[0])
log("end_load")

log("start_balances")
balances = ledger.balances
log("end_balances")

log("start_pp")
pp balances
log("end_pp")
