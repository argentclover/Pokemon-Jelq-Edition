module Battle
  class Logic
    class DamageHandler < ChangeHandlerBase
      # Processes the damage dealt to a boss or another Pokémon.
      # @param hp [Integer] The amount of HP (damage) dealt.
      # @param target [PFM::PokemonBattler] The target Pokémon receiving the damage.
      # @param launcher [PFM::PokemonBattler, nil] The Pokémon that launched the move, if applicable.
      # @param skill [Battle::Move, nil] The move used, if applicable.
      # @param messages [Proc] The messages shown right before the post-processing.
      def damage_change(hp, target, launcher = nil, skill = nil, &messages)
        hp = calculate_damage(hp, target, launcher, skill, &messages)

        target.add_damage_to_history(hp, launcher, skill, target.hp <= 0)
        log_data("# damage_change(#{hp}, #{target}, #{launcher}, #{skill}, #{target.hp <= 0})")
      rescue Hooks::ForceReturn => e
        log_data("# FR: damage_change : #{e.data} from #{e.hook_name} (#{e.reason})")
        return e.data
      ensure
        scene.visual.refresh_info_bar(target)
      end

      # Function that drains a certain quantity of HP from the target and gives it to the user.
      # @param hp_factor [Integer] The division factor of HP to drain.
      # @param target [PFM::PokemonBattler] The target that gets HP drained.
      # @param launcher [PFM::PokemonBattler] The launcher of a draining move/effect.
      # @param skill [Battle::Move, nil] The potential move used.
      # @param hp_overwrite [Integer, nil] The number of HP drained by the move, if provided.
      # @param drain_factor [Integer] The division factor of HP drained.
      # @param messages [Proc] The messages shown right before the post-processing.
      def drain(hp_factor, target, launcher, skill = nil, hp_overwrite: nil, drain_factor: 1, &messages)
        hp = hp_overwrite || (target.max_hp / hp_factor).clamp(1, Float::INFINITY)
        hp = calculate_damage(hp, target, launcher, skill, &messages)
        handle_drain_effects(hp, target, launcher, skill, drain_factor, &messages)

        target.add_damage_to_history(hp, launcher, skill, target.hp <= 0)
        log_data("# damage_change(#{hp}, #{target}, #{launcher}, #{skill}, #{target.hp <= 0})")
      rescue Hooks::ForceReturn => e
        log_data("# FR: drain : #{e.data} from #{e.hook_name} (#{e.reason})")
        return e.data
      ensure
        scene.visual.refresh_info_bar(target)
      end

      private

      # Calculates the damage dealt, checks for knockout, and updates the skill damage if applicable.
      # @param hp [Integer] The amount of HP (damage) dealt.
      # @param target [PFM::PokemonBattler] The target Pokémon receiving the damage.
      # @param launcher [PFM::PokemonBattler, nil] The Pokémon that launched the move, if applicable.
      # @param skill [Battle::Move, nil] The move used, if applicable.
      # @param messages [Proc] The messages shown right before the post-processing.
      # @return [Integer] The calculated damage.
      def calculate_damage(hp, target, launcher, skill, &messages)
        hp = hp.clamp(1, target.hp)
        is_KO = hp >= target.hp

        update_skill_damage(skill, hp, target) if skill

        if is_KO
          handle_knockout(hp, target, launcher, skill, &messages)
        else
          show_damage_animation(hp, target, launcher, skill, &messages)
          exec_hooks(DamageHandler, :post_damage, binding)
        end

        return hp
      end

      # Handles the specific logic for draining HP and transferring it to the launcher.
      # @param hp [Integer] The amount of HP (damage) dealt.
      # @param target [PFM::PokemonBattler] The target Pokémon receiving the damage.
      # @param launcher [PFM::PokemonBattler] The launcher of a draining move/effect.
      # @param skill [Battle::Move, nil] The move used, if applicable.
      # @param drain_factor [Integer] The division factor of HP drained.
      # @param messages [Proc] The messages shown right before the post-processing.
      def handle_drain_effects(hp, target, launcher, skill, drain_factor, &messages)
        return handle_liquid_ooze_effect(hp, target, launcher, skill, drain_factor, &messages) if target.has_ability?(:liquid_ooze)

        hp_healed = calculate_healed_hp(hp, target, launcher, skill, drain_factor)
        heal(launcher, hp_healed)
        scene.display_message_and_wait(parse_text_with_pokemon(19, 905, target))
      end

      # Handle the liquid ooze ability effect.
      # @param hp [Integer] The amount of HP (damage) dealt.
      # @param target [PFM::PokemonBattler] The target Pokémon receiving the damage.
      # @param launcher [PFM::PokemonBattler] The launcher of a draining move/effect.
      # @param skill [Battle::Move, nil] The move used, if applicable.
      # @param drain_factor [Integer] The division factor of HP drained.
      # @param messages [Proc] The messages shown right before the post-processing.
      def handle_liquid_ooze_effect(hp, target, launcher, skill, drain_factor, &messages)
        scene.visual.show_ability(target)
        damage_change(hp, launcher)
        scene.display_message_and_wait(parse_text_with_pokemon(19, 457, launcher))
      end

      # Calculates the amount of HP healed based on various factors.
      # @param hp [Integer] The amount of HP (damage) dealt.
      # @param target [PFM::PokemonBattler] The target Pokémon receiving the damage.
      # @param launcher [PFM::PokemonBattler] The launcher of a draining move/effect.
      # @param skill [Battle::Move, nil] The move used, if applicable.
      # @param drain_factor [Integer] The division factor of HP drained.
      # @return [Integer] The amount of HP healed.
      def calculate_healed_hp(hp, _, launcher, skill, drain_factor)
        hp *= 1.3 if launcher.hold_item?(:big_root)
        hp *= 1.5 if skill&.pulse? && launcher.has_ability?(:mega_launcher)
        hp /= drain_factor
        hp = hp.to_i.clamp(1, Float::INFINITY)

        return hp
      end

      # Updates the damage dealt by the skill and records the last move that hit the target.
      # @param skill [Battle::Move] The move used to deal the damage.
      # @param hp [Integer] The amount of damage dealt.
      # @param target [PFM::PokemonBattler] The target Pokémon receiving the damage.
      def update_skill_damage(skill, hp, target)
        skill.damage_dealt += hp
        target.last_hit_by_move = skill
      end

      # Handles the knockout of a Pokémon, considering special cases for bosses.
      # @param hp [Integer] The amount of HP (damage) dealt.
      # @param target [PFM::PokemonBattler] The target Pokémon receiving the damage.
      # @param launcher [PFM::PokemonBattler, nil] The Pokémon that launched the move, if applicable.
      # @param skill [Battle::Move, nil] The move used, if applicable.
      # @param messages [Proc] The messages shown right before the post-processing.
      def handle_knockout(hp, target, launcher, skill, &messages)
        if target.boss? && target.nb_bars_hp > 1
          handle_boss_bar_removal(hp, target, launcher, skill, &messages)
        else
          show_damage_animation(hp, target, launcher, skill, &messages)
          exec_hooks(DamageHandler, :post_damage_death, binding)
          target.ko_count += 1
        end
      end

      # Handles the removal of a health bar from a boss.
      # @param hp [Integer] The amount of HP (damage) dealt.
      # @param target [PFM::PokemonBattler] The target Pokémon receiving the damage.
      # @param launcher [PFM::PokemonBattler, nil] The Pokémon that launched the move, if applicable.
      # @param skill [Battle::Move, nil] The move used, if applicable.
      # @param messages [Proc] The messages shown right before the post-processing.
      def handle_boss_bar_removal(hp, target, launcher, skill, &messages)
        show_damage_animation(hp - 1, target, launcher, skill, &messages)
        target.nb_bars_hp -= 1
        scene.visual.boss_battle_clear_bar(target.bank, target.position, target.nb_bars_hp)
        heal(target, target.max_hp)
        exec_hooks(DamageHandler, :post_damage_death, binding)
        target.ko_count += 1
        logic.actions.clear
      end

      # Show the damage animation on the target.
      # @param hp [Integer] The amount of HP (damage) dealt.
      # @param target [PFM::PokemonBattler] The target Pokémon receiving the damage.
      # @param launcher [PFM::PokemonBattler, nil] The Pokémon that launched the move, if applicable.
      # @param skill [Battle::Move, nil] The move used, if applicable.
      # @param messages [Proc] The messages shown right before the post-processing.
      def show_damage_animation(hp, target, launcher, skill, &messages)
        scene.visual.show_hp_animations([target], [-hp], [skill&.effectiveness], &messages)
      end
    end
  end
end
