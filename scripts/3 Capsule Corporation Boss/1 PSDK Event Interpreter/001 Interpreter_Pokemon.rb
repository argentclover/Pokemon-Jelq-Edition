class Interpreter
  # Start a Boss battle
  # @param hash [Hash] the parameters of the Pokemon, see PFM::Pokemon::generate_from_hash
  # @param id [Integer] id of the scenarize battle to get the right Boss Effect
  def call_battle_boss(hash, id = 1)
    $wild_battle.start_battle(hash, battle_id: id)
    @wait_count = 2
  end
end
