# frozen_string_literal: true

module HasId
  def account
    id.split(':')[0]
  end

  def kind
    id.split(':')[1]
  end

  def identifier
    id.split(':', 3)[2]
  end
end
