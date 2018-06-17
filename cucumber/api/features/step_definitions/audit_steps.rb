Then(/^the last audit record matches:$/) do |given|
  expect(last_message).to match audit_template given
end

Then(/^there is an audit record matching:$/) do |given|
  expect(audit_messages).to include(matching(audit_template(given))),
    "Audit messages:\n#{Test::AuditSink.messages.join}"
end

module CucumberAuditHelper
  def audit_messages
    # Since the message to match is probably near the end, 
    # reverse the list and only lazily do the normalization.
    Test::AuditSink.messages.reverse.lazy.map(&method(:normalize_message))
  end

  def last_message
    normalize_message Test::AuditSink.messages.last
  end

  def audit_template template
    normalize_message(template).map(&method(:matcher))
  end
  
  private

  # I suppose it's acceptable to :reek:UtilityFunction
  # for this test-related method
  def normalize_message message
    raise ArgumentError, "no audit message received" unless message
    *fields, tail = message
      .gsub(/\s+/m, ' ')
      .gsub(/\] \[/, '][')
      .split(' ', 7)
    *sdata, msg = tail.split(/(?<=\])/).map(&:strip)
    sdata, msg = msg.split ' ', 2 if sdata.empty?
    [*fields, sdata, msg]
  end
  
  def matcher val
    case val
    when '*' then be
    when Array then match_array val
    else match val
    end
  end
end

Before { Test::AuditSink.messages.clear }

World CucumberAuditHelper
