# Here's an example of how to give a Boss effect to a Pokémon that should be a Boss
Battle::Scene.register_event(:logic_init) do |scene|
  scene.logic.battler(1, 0).effects.add(Battle::Effects::CharizardBoss.new(scene.logic, scene.logic.battler(1, 0)))
end