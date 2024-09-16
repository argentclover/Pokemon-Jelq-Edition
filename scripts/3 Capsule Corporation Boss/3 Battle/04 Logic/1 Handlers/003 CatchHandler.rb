module Battle
  class Logic
    # Handler responsive of answering properly Pokemon catching requests
    class CatchHandler < ChangeHandlerBase
      Hooks.register(Battle::Logic::CatchHandler, :ball_blocked, 'Check if catching is forbidden in this battle') do |hook_binding|
        next unless hook_binding[:target].boss?

        # TODO: Add the corresponding animation
        # TODO: Add the corresponding text
        force_return(false)
      end
    end
  end
end
