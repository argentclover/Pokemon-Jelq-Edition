module Battle
  module Effects
    class CharizardBoss < PokemonTiedEffectBase
      # Function called after damages were applied (post_damage, when target is still alive)
      # @param handler [Battle::Logic::DamageHandler]
      # @param hp [Integer] number of hp (damage) dealt
      # @param target [PFM::PokemonBattler]
      # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
      # @param skill [Battle::Move, nil] Potential move used
      def on_post_damage_death(handler, _hp, target, _launcher, _skill)
        return unless target.boss? && target.nb_bars_hp > 0

        z_log("Applying the effect when a bar is lost")
      end

      # Function giving the name of the effect
      # @return [Symbol]
      def name
        return :charizard_boss
      end
    end
  end
end
