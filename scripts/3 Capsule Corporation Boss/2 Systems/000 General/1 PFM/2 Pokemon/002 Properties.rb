module PFM
  class Pokemon
    # Return if the Pokemon is a Boss.
    # @return [Boolean]
    attr_reader :is_Boss
    # The number of hp bars the Pokemon has.
    # @return [Integer]
    attr_accessor :nb_bars_hp
  end
end
