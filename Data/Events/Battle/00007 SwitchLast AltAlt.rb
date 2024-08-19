module Battle
  module AI
    class SwitchLastlv5 < TrainerLv5
      # Determines if a Pokémon can be switched out based on its position and some additional factors.
      # @param action [Actions::Switch]
      # @return [Boolean]
      def can_switch_be_performed?(action)
        with = action.with
        party_size = scene.logic.battle_info.party(with).size
        is_last = with.place_in_party == party_size - 1
        !is_last && super
      end

      # Cleans up the switch actions by excluding invalid ones.
      # @param actions [Array<[Float, Actions::Switch]>]
      # @return [Array<[Float, Actions::Switch]>]
      def clean_switch_actions(actions)
        actions = super

        # Get all alive battlers from the AI's party
        all_from_ai = scene.logic.alive_battlers_without_check(bank).select { |i| i.party_id == party_id }
        
        # If there are no other Pokémon to switch to (e.g., only the last Pokémon remains), return original actions
        if all_from_ai.size <= 1 || all_from_ai.none? { |battler| battler.place_in_party != scene.logic.battle_info.party_size - 1 }
          return actions
        end

        # Filter actions to exclude those that switch to the last Pokémon
        actions.reject { |action| is_last_pokemon?(action.with) }
      end

      private

      # Checks if the Pokémon is the last one in the party.
      # @param pokemon [Pokemon] The Pokémon to check
      # @return [Boolean] True if the Pokémon is in the last slot
      def is_last_pokemon?(pokemon)
        party_size = scene.logic.battle_info.party(pokemon).size
        pokemon.place_in_party == party_size - 1
      end

      Base.register(15, self)
    end
  end
end
