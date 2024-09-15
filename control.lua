---get the text from an existing combinator
---@param combinator LuaEntity?
---@return string
local function get_combinator_text(combinator)
    local text = ""
    if combinator and combinator.valid then
        local control = combinator.get_control_behavior() --[[@as LuaConstantCombinatorControlBehavior]]
        if control and control.valid then
            local blank = 0
            ---@type uint
            for i = 1, control.signals_count do
                local signal = control.get_signal(i).signal
                if not signal then
                    blank = blank + 1
                else
                    for _ = 1, blank do
                        text = text .. " "
                    end
                    blank = 0
                    if signal.type ~= "virtual" or signal.name:len()~=8 or signal.name:sub(1,7) ~= "signal-" then
                        text = text .. "_"
                    else
                        text = text .. signal.name:sub(8,8)
                    end
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
    if not entity or not entity.valid or entity.type ~= "constant-combinator" then return end
    local player = game.get_player(event.player_index)
    if not player then return end

    -- destroy the frame if it still exists from previously
    local relative_frame = player.gui.relative["combinator-text"]
    if relative_frame then relative_frame.destroy() end

    -- anchor the frame below the constant combinator gui
    ---@type GuiAnchor
    local anchor = {gui=defines.relative_gui_type.constant_combinator_gui, position=defines.relative_gui_position.bottom}
    local frame = (player.gui.relative.add{type="frame", anchor=anchor, name="combinator-text", caption="Combinator Text", direction="vertical"})--[[@as LuaGuiElement.frame]]
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
        if combinator and combinator.valid then
            local text = element.parent["textfield"]--[[@as LuaGuiElement.textfield]].text
            local control = combinator.get_control_behavior()--[[@as LuaConstantCombinatorControlBehavior]]
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
            for i = math.min(#text, control.signals_count) + 1, control.signals_count do
                control.set_signal(i, nil)
            end
        end
    end
end

---Limit text length to signal count of the combinator
---@param event EventData.on_gui_elem_changed
local function on_gui_text_changed(event)
    local element = event.element
    if
        element.valid and element.parent and element.parent.name == "combinator-text" and element.type == "textfield"
    then
        local combinator = game.get_player(event.player_index).opened
        if combinator and combinator.valid then
            local control = combinator.get_control_behavior()--[[@as LuaConstantCombinatorControlBehavior]]
            element.parent["textfield"].text = string.sub(element.parent["textfield"]--[[@as LuaGuiElement.textfield]].text, 1, control.signals_count)
        end
    end
end

script.on_event(defines.events.on_gui_opened, on_gui_opened)
script.on_event(defines.events.on_gui_click, on_gui_apply)
script.on_event(defines.events.on_gui_confirmed, on_gui_apply)
script.on_event(defines.events.on_gui_text_changed, on_gui_text_changed)
