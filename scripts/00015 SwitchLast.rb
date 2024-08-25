module Battle
  # Module holding the whole AI code
  module AI
    class SwitchLastlv7 < TrainerLv7
      # Function that clean the switch action:
      #  - Exclude duplicate switch in action
      #  - Ensure a Pokemon that is already on the field cannot get in the field
      # @param actions [Array<[Float, Actions::Switch]>]
      # @return [Array<[Float, Actions::Switch]>]
      def clean_switch_actions(actions)
        actions = super
        all_from_ai = scene.logic.alive_battlers_without_check(bank).select { |i| i.party_id == party_id }
        return actions if all_from_ai.size <= 1 || actions.size <= 1

        last_place_in_party = scene.logic.battle_info.party(actions[0][1].with).size - 1
        return actions.select { |action| action[1].with.place_in_party != last_place_in_party }
      end

      Base.register(15, self)
    end
  end
end