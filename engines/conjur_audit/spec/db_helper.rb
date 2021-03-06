# frozen_string_literal: true

shared_context "database setup" do
  let(:db) { Sequel::Model.db }

  before { db[:messages].truncate }

  around do |ex|
    db.transaction do
      ex.call
      raise Sequel::Rollback
    end
  end

  # :reek:UtilityFunction should be ok in tests
  def add_message msg, props = {}
    sdata = props[:sdata]
    ConjurAudit::Message.create({
      facility: 4,
      severity: 5,
      timestamp: Time.now,
      message: msg,
      sdata: sdata && Sequel.pg_jsonb(sdata)
    }
    .merge(props.except(:sdata)))
  end
end
