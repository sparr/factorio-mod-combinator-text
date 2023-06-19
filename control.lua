---get the text from an existing combinator
---@param combinator LuaEntity?
---@return string
local function get_combinator_text(combinator)
    local text = ""
    if combinator and combinator.valid then
        local control = combinator.get_control_behavior() --[[@as LuaConstantCombinatorControlBehavior]]
        if control and control.valid then
            local skip = 0
            ---@type uint
            for i = 1, control.signals_count do
                local signal = control.get_signal(i).signal
                local c = nil
                if signal and signal.type == "virtual" and signal.name:len()==8 and signal.name:sub(1,7) == "signal-" then
                    c = signal.name:sub(8,8)
                    -- add a space for every signal or slot we skipped due to it being empty or non-text
                    for e = 1, skip do
                        text = text .. "_"
                    end
                    skip = 0
                    text = text .. c
                else
                    skip = skip + 1
                end
            end
        end
    end
    return text
end

---when opening a constant combinator, create and populate the mod gui
---@param event EventData.on_gui_opened
local function on_gui_opened(event)
    local entity = event.entity
    if not entity or entity.type ~= "constant-combinator" then return end
    local player = game.get_player(event.player_index)
    if not player then return end

    -- destroy the frame if it still exists from previously
    local relative_frame = player.gui.relative["combinator-text"]
    if relative_frame then relative_frame.destroy() end

    -- anchor the frame below the constant combinator gui
    ---@type GuiAnchor
    local anchor = {gui=defines.relative_gui_type.constant_combinator_gui, position=defines.relative_gui_position.bottom}
    -- create the frame
    ---@type LuaGuiElement
    local frame = player.gui.relative.add{type="frame", anchor=anchor, name="combinator-text", caption="Combinator Text", direction="vertical"}
    frame.add{type="textfield", name="textfield", text=get_combinator_text(entity)}
    frame.add{type="button", name="button", caption="Apply"}
end

---use the text in a player's mod gui to set the signals in their open combinator
---@param event EventData.on_gui_click | EventData.on_gui_confirmed
local function on_gui_apply(event)
    local element = event.element
    if
        element.valid and element.parent and element.parent.name == "combinator-text" and
        (
            (event.name == defines.events.on_gui_click and element.type == "button") or
            (event.name == defines.events.on_gui_confirmed and element.type == "textfield")
        )
    then
        local combinator = game.get_player(event.player_index).opened
        local text = element.parent["textfield"].text
        if combinator and combinator.valid then
            local control = combinator.get_control_behavior() --[[@as LuaConstantCombinatorControlBehavior]]
            ---@type uint
            for i = 1, math.min(#text, control.signals_count) do
                local char = text:sub(i,i):upper()
                if char == " " then
                    control.set_signal(i, nil)
                else
                    local signal = "signal-" .. char
                    if game.virtual_signal_prototypes[signal] then
                        control.set_signal(i, {signal={type="virtual",name=signal}, count=0})
                    end
                end
            end
            ---@type uint
            for i = math.min(#text, control.signals_count) + 1, math.max(#text, control.signals_count) do
                control.set_signal(i, nil)
            end
        end
    end
end

script.on_event(defines.events.on_gui_opened, on_gui_opened)
script.on_event(defines.events.on_gui_click, on_gui_apply)
script.on_event(defines.events.on_gui_confirmed, on_gui_apply)
