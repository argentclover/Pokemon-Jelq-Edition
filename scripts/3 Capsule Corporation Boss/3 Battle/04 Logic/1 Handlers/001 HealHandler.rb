module Battle
  class Logic
    class DamageHandler < ChangeHandlerBase
      # Function that proceeds to heal a Pokemon.
      # @param target [PFM::PokemonBattler] The Pokemon that will be healed.
      # @param hp [Integer] The number of HP to heal.
      # @param test_heal_block [Boolean] Whether to test if healing is blocked. Defaults to true.
      # @param animation_id [Symbol, Integer] The animation to use instead of the default one. Optional.
      # @yieldparam hp [Integer] The actual amount of HP healed.
      # @return [Boolean] True if the heal was successful, false otherwise.
      def heal(target, hp, test_heal_block: true, animation_id: nil)
        return false if healing_not_allowed?(target, hp, test_heal_block)

        actual_hp = hp.clamp(1, target.max_hp)
        process_healing(target, actual_hp, animation_id)

        return true
      end

      private

      # Check if healing is not allowed due to blocks or target conditions.
      # @param target [PFM::PokemonBattler]
      # @param hp [Integer]
      # @param test_heal_block [Boolean]
      # @return [Boolean]
      def healing_not_allowed?(target, hp, test_heal_block)
        return true if heal_blocked?(target, test_heal_block)
        return true unless can_heal?(target, hp)

        return false
      end

      # Check if healing is blocked for the target.
      # @param target [PFM::PokemonBattler]
      # @param test_heal_block [Boolean]
      # @return [Boolean]
      def heal_blocked?(target, test_heal_block)
        if test_heal_block && target.effects.has?(:heal_block)
          @scene.display_message_and_wait(parse_text_with_pokemon(19, 890, target))
          return true
        end

        return false
      end

      # Check if the target can be healed.
      # @param target [PFM::PokemonBattler]
      # @param hp [Integer]
      # @return [Boolean]
      def can_heal?(target, hp)
        return true if target.hp < target.max_hp
        return true if target.boss? && target.nb_bars_hp < 5

        @scene.display_message_and_wait(parse_text_with_pokemon(19, 896, target))
        return false
      end

      # Process the healing logic for the target.
      # @param target [PFM::PokemonBattler]
      # @param actual_hp [Integer]
      # @param animation_id [Symbol, Integer]
      def process_healing(target, actual_hp, animation_id)
        if can_add_bar?(target, actual_hp)
          add_bar(target, actual_hp, animation_id)
        else
          apply_healing_effect(target, actual_hp, animation_id)
        end
      end

      # Check if the Boss can regenerate a bar.
      # @param target [PFM::PokemonBattler]
      # @param actual_hp [Integer]
      # @return [Boolean]
      def can_add_bar?(target, actual_hp)
        return false unless target.boss?
        return false if target.nb_bars_hp == 5
        return false unless actual_hp + target.hp > target.max_hp + 1

        return true
      end

      # Add a bar for the Boss.
      # @param target [PFM::PokemonBattler]
      # @param actual_hp [Integer]
      # @param animation_id [Symbol, Integer]
      def add_bar(target, actual_hp, animation_id)
        excess_hp = actual_hp + target.hp - target.max_hp
        target.nb_bars_hp += 1
        scene.visual.boss_battle_add_bar(target.bank, target.position, target.nb_bars_hp)
        apply_healing_effect(target, -target.max_hp + excess_hp, animation_id)
      end

      # Apply the healing effect to the target.
      # @param target [PFM::PokemonBattler] The Pokemon that will receive the healing effect.
      # @param actual_hp [Integer] The actual amount of HP to apply.
      # @param animation_id [Symbol, Integer] The animation to use for the healing effect. Optional.
      # @yieldparam actual_hp [Integer] The actual amount of HP healed, passed to the block if provided.
      def apply_healing_effect(target, actual_hp, animation_id)
        if target.can_fight?
          scene.visual.show_hp_animations([target], [actual_hp])
        else
          target.hp += actual_hp
        end

        block_given? ? yield(actual_hp) : scene.display_message_and_wait(parse_text_with_pokemon(19, 387, target))
      end
    end
  end
end
