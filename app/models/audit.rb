require 'syslog'
require 'logger'
require 'time'

module Audit
  def self.notice msg, msgid, data
    logger.info LogMessage.new msg, msgid, data, Syslog::LOG_NOTICE
  end

  module SDID
    CONJUR_PEN = 43838
    def self.conjur_sdid label
      [label, CONJUR_PEN].join('@').freeze
    end

    POLICY = conjur_sdid 'policy'
    AUTH = conjur_sdid 'auth'
    SUBJECT = conjur_sdid 'subject'
    ACTION = conjur_sdid 'action'
  end

  def self.logger
    @logger ||= Rails.logger
  end

  class LogMessage < String
    def initialize msg, msgid, structured_data = nil, severity = nil
      super msg
      @msgid = msgid
      @structured_data = structured_data
      @severity = severity
    end

    attr_reader :msgid, :structured_data, :severity
  end

  class RFC5424Formatter
    SEVERITY_MAP = {
      Logger::Severity::DEBUG => Syslog::LOG_DEBUG,
      Logger::Severity::ERROR => Syslog::LOG_ERR,
      Logger::Severity::FATAL => Syslog::LOG_CRIT,
      Logger::Severity::INFO => Syslog::LOG_INFO,
      Logger::Severity::WARN => Syslog::LOG_WARNING
    }

    # TODO
    FACILITY = 32

    def call severity, time, progname, msg
      severity = if msg.respond_to? :severity
        msg.severity
      else
        SEVERITY_MAP[Logger::Severity.const_get severity]
      end
      sd = msg.structured_data if msg.respond_to? :structured_data
      timestamp = time.utc.iso8601 3

      # TODO
      hostname = nil
      pid = nil

      msgid = msg.msgid if msg.respond_to? :msgid
      sd = format_sd sd

      fields = [timestamp, hostname, progname, pid, msgid, sd, msg]
      ["<#{severity + FACILITY}>1", *fields.map {|x| x || '-'}].join(" ") + "\n"
    end

  private
    def format_sd sd
      return '-' unless sd
      sd.map do |id, params|
        "[%s]" % [[id,
          params.map do |k, v|
            "#{k}=#{v.to_s.inspect}"
          end
        ].join(" ")]
      end.join
    end
  end
end

