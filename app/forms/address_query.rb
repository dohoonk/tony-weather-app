class AddressQuery
  attr_reader :raw

  def initialize(raw)
    @raw = raw.to_s
  end

  def value
    @value ||= raw.strip.presence
  end

  def present?
    value.present?
  end
end
