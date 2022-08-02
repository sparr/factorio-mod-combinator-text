global.text = global.text or {}
global.dialog = global.dialog or {}
global.combinator = global.combinator or {}
global.reopens = global.reopens or {}

-- when opening a constant combinator, open the mod gui with any saved text from previous use
local function on_gui_opened(event)
    local entity = event.entity
    if not entity or entity.type ~= "constant-combinator" then return end
    local player_index = event.player_index
    global.combinator[player_index] = entity
    local dialog = game.players[player_index].gui.left.add{type="frame", name="combinator_text", caption="Combinator Text", direction="vertical"}
    dialog.add{type="textfield", name="textfield", text=global.text[player_index]}
    dialog.add{type="button", name="button", caption="Apply"}
    global.dialog[player_index] = dialog
end

-- remember the entered text, close the mod gui, forget the gui and what combinator the player had open
local function close_gui(player_index)
    local dialog = global.dialog[player_index]
    if dialog and dialog.valid then
        global.text[player_index] = dialog.textfield.text
        dialog.destroy()
    end
    global.dialog[player_index] = nil
    global.combinator[player_index] = nil
end

-- when closing a constant combinator, close the mod gui
local function on_gui_closed(event)
    local entity = event.entity
    if not entity or entity.type ~= "constant-combinator" then return end
    close_gui(event.player_index)
end

-- when entering or exiting the editor, close the mod gui
local function on_player_toggled_map_editor(event)
    close_gui(event.player_index)
end

-- after a combinator has been changed, reopen its gui to see the change
local function handle_reopens()
    for index, reopen in pairs(global.reopens) do
        if reopen.player.valid and reopen.combinator.valid and reopen.tick == game.tick then
            reopen.player.opened = reopen.combinator
            global.reopens[index] = nil
        end
    end
    script.on_nth_tick(game.tick, nil)
end

-- use the text in a player's mod gui to set the signals in their open combinator
local function set_combinator_text(player_index)
    local player = game.players[player_index]
    local combinator = global.combinator[player_index]
    local text = global.dialog[player_index].textfield.text
    if combinator.valid then
        local control = combinator.get_control_behavior()
        for i = 1, math.min(#text, control.signals_count)  do
            local c = text:sub(i,i):upper()
            -- non-alphanumeric characters get skipped and don't change the combinator signals in those positions
            if (c >= "A" and c <= "Z") or (c >= "0" and c <= "9") then
                local signal = "signal-" .. c
                control.set_signal(i, {signal={type="virtual",name=signal}, count=0})
            end
        end
        player.opened = nil
        -- schedule re-opening this combinator gui on the next tick
        global.reopens[#global.reopens + 1] = {player=player, combinator=combinator, tick=game.tick+1}
        script.on_nth_tick(game.tick+1, handle_reopens)
    else
        close_gui(player_index)
    end
end

-- there are probably best practices worth implementing here
local function on_gui_click(event)
    local element = event.element
    local player_index = event.player_index
    local dialog = global.dialog[player_index]
    if element.parent == dialog and element.type == "button" then
        set_combinator_text(player_index)
    end
end

-- set the combinator text when the player applies their input
local function on_gui_confirmed(event)
    local element = event.element
    local player_index = event.player_index
    local dialog = global.dialog[player_index]
    if element.parent == dialog and element.type == "textfield" then
        set_combinator_text(player_index)
    end
end

script.on_load(function() if next(global.reopens) then script.on_nth_tick(game.tick+1, handle_reopens) end end)
script.on_event(defines.events.on_gui_opened, on_gui_opened)
script.on_event(defines.events.on_gui_closed, on_gui_closed)
script.on_event(defines.events.on_gui_click, on_gui_click)
script.on_event(defines.events.on_gui_confirmed, on_gui_confirmed)
script.on_event(defines.events.on_player_toggled_map_editor, on_player_toggled_map_editor)
