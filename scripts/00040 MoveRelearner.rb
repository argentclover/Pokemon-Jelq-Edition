module GamePlay
    class Summary
      alias psdk_update_inputs_skill_ui update_inputs_skill_ui
      def update_inputs_skill_ui
        if Input.trigger?(:A)
          GamePlay.open_move_reminder(@pokemon) 
          update_pokemon
        end
        psdk_update_inputs_skill_ui
      end
    end
  end