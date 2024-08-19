module Battle
  # Module holding the whole AI code
  module AI
    class SwitchLastlv5 < TrainerLv5
      # Function that tell if a Pokemon can be switched out based on the current turn & some random factor
      # @param action [Actions::Switch]
      # @return [Boolean]
      def can_switch_be_performed?(action)
        with = action.with
        party_size = scene.logic.battle_info.party(with).size
        is_last = with.place_in_party == party_size - 1
        
        if is_last && scene.logic.alive_battlers_without_check(1).size == 1
          return true
        elsif is_last && scene.logic.alive_battlers_without_check(1).size > 1
          return false
        end

        return is_last ? false : super

        puts(with.place_in_party)
        puts(party_size)
      end

      # Function that clean the switch action:
      #  - Exclude duplicate switch in action
      #  - Ensure a Pokemon that is already on the field cannot get in the field
      # @param actions [Array<[Float, Actions::Switch]>]
      # @return [Array<[Float, Actions::Switch]>]
      def clean_switch_actions(actions)
        actions = super
        all_from_ai = scene.logic.alive_battlers_without_check(bank).select { |i| i.party_id == party_id }
        return actions if all_from_ai.size <= 1

        return actions.select { |action| can_switch_be_performed?(action) }
        puts(all_from_ai.size)
      end

      Base.register(5, self)
    end
  end
end