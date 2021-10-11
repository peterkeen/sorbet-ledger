# frozen_string_literal: true
# typed: strict

require 'digest'
require 'json'
require 'sorbet-runtime'
require 'fileutils'

module SorbetLedger
  Metadata = T.type_alias { T::Hash[Symbol, T.untyped] }
  Currency = T.type_alias { String }

  class Account < T::Struct
    const :name, String
    const :metadata, Metadata, default: {}
  end

  class JournalEntry < T::Struct
    const :account, Account    
    const :currency, Currency
    const :amount, Integer
    const :metadata, Metadata, default: {}
  end

  class Transaction < T::Struct
    extend T::Sig

    const :timestamp, Integer
    const :note, String
    const :entries, T::Array[JournalEntry]
    const :metadata, Metadata, default: {}

    sig {params(hash: T::Hash[Symbol, T.untyped]).void.checked(:never)}
    def initialize(hash={})
      super

      valid?
    end

    sig {void}
    def valid?
      valid = entries.group_by(&:currency).all? do |_, group|
        group.sum(&:amount) == 0
      end

      raise "Invalid transaction: entries do not balance" unless valid
    end

    sig {returns(String)}
    def txn_hash
      time = self.timestamp.to_s(36)
      digest = Digest::SHA256.hexdigest(self.serialize.to_json).to_i(16).to_s(36)

      "#{time}_#{digest}"
    end
  end

  class Ledger < T::Struct
    extend T::Sig

    const :metadata, Metadata, default: {}
    const :transactions, T::Array[Transaction], default: []

    sig { params(path: String).returns(Ledger) }
    def self.from_path(path)
      metadata = JSON.parse(File.read(File.join(path, 'metadata.json')))      
      ledger = self.new(metadata: metadata)

      Dir.glob(File.join(path, 'transactions/**/*.json')) do |filepath|
        if File.file?(filepath)
          txn = JSON.parse(File.read(filepath))
          ledger.transactions << Transaction.from_hash(txn)
        end
      end

      ledger
    end

    sig { params(path: String).void }
    def save_to_path(path)
      FileUtils.mkdir_p(path)
      FileUtils.mkdir_p(File.join(path, 'transactions'))

      File.write(File.join(path, 'metadata.json'), metadata.to_json)

      transactions.each do |txn|
        txn_hash = txn.txn_hash
        prefix_dir = File.join(path, 'transactions', txn_hash.split('_')[1][0, 2])
        FileUtils.mkdir_p(prefix_dir)
        txn_path = File.join(prefix_dir, txn.txn_hash + ".json")
        next if File.exist?(txn_path)

        File.write(txn_path, txn.serialize.to_json)
      end
    end

    sig { returns(T::Hash[Account, T::Hash[Currency, Integer]]) }
    def balances
      balances_by_account_currency = Hash.new {|ah,acct| ah[acct] = Hash.new {|ch,curr| ch[curr] = 0 }}

      transactions.map(&:entries).flatten.each do |entry|
        balances_by_account_currency[entry.account.name][entry.currency] += entry.amount
      end

      balances_by_account_currency
    end
  end
end
