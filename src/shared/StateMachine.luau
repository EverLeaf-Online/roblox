local StateMachine = {}
StateMachine.__index = StateMachine

function StateMachine.new(initialState, transitions)
    assert(type(initialState) == "string" and initialState ~= "", "initialState must be a string")
    return setmetatable({ State = initialState, Transitions = transitions or {} }, StateMachine)
end

function StateMachine:CanTransition(nextState)
    local allowed = self.Transitions[self.State]
    if not allowed then
        return false
    end
    for _, candidate in allowed do
        if candidate == nextState then
            return true
        end
    end
    return false
end

function StateMachine:Transition(nextState)
    if not self:CanTransition(nextState) then
        return false, "invalid_transition"
    end
    local previous = self.State
    self.State = nextState
    return true, previous
end

function StateMachine:GetState()
    return self.State
end

return StateMachine
