module PFM
  class Wild_Battle
    private

    # Configure the Wild battle
    # @param enemy_arr [Array<PFM::Pokemon>] Array of enemy Pokemon to battle.
    # @param battle_id [Integer] ID of the events to load for the battle scenario.
    # @return [Battle::Logic::BattleInfo, nil]
    def configure_battle(enemy_arr, battle_id)
      return if (!enemy_arr.is_a? Array) || !enemy_arr || enemy_arr&.empty?

      info = Battle::Logic::BattleInfo.new
      info.add_party(0, *info.player_basic_info)
      add_ally_trainer(info, $game_variables[Yuki::Var::Allied_Trainer_ID])
      info.add_party(1, enemy_arr, nil, nil, nil, nil, nil, pokemon_ai(enemy_arr))
      info.battle_id = battle_id
      info.fishing = !@fish_battle.nil?
      info.vs_type = 2 if enemy_arr.size >= 2
      return info
    end

    # Determine the AI level for the enemy Pokémon.
    # @param enemy_arr [Array<PFM::Pokemon>] Array of enemy Pokémon to evaluate.
    # @return [Integer] Returns the AI level:
    #   - -1 if any Pokémon is roaming,
    #   - 3 if any Pokémon is a boss,
    #   - 0 as the default AI level.
    def pokemon_ai(enemy_arr)
      return -1 if enemy_arr.any? { |pokemon| roaming?(pokemon) }
      return 3 if enemy_arr.any? { |pokemon| pokemon.is_Boss }

      return 0
    end
  end
end
