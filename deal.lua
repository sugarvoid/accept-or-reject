-- title:   Accept or Reject
-- author:  sugarvoid
-- desc:    Like deal or no deal. By like, I mean the same thing.
-- license: MIT License
-- version: 1.0
-- script:  lua
-- input: keyboard

local selector_index = { 0, 0 }
local BORDER_COLOR = 12
local can_player_input = true
local last_case = nil

local GAMESTATES = {
    title = 0,
    pick_case = 1,
    display_values = 2,
    offer = 3,
    game_over = 5,
    deal_accepted = 6
}
local game_state = GAMESTATES.title
local FONT_COLOR = 4
local round = 0
local please_rename = { 6, 5, 4, 3, 2, 1, 1, 1, 0 }

local top_bar = {
    x = 0,
    y = 2,
    str = "",
    w = 0,
    col = FONT_COLOR,
    set_text = function(self, text)
        self.str = text
        self.w = print(text, 0, -6)
    end,
    draw = function(self)
        print(self.str, self.x, self.y, FONT_COLOR)
    end,
    update = function(self)
        self.x = self.x - 0.5
        if self.x + self.w <= 0 then
            self.x = 241
        end
    end,
}

local opening_case_t = 0
local row_1_y = 15 + 2
local row_2_y = 35 + 2
local row_3_y = 55 + 2
local row_4_y = 75 + 2

local col_1 = 30 - 20
local col_2 = 55 - 20
local col_3 = 80 - 20
local col_4 = 105 - 20
local col_5 = 130 - 20
local col_6 = 155 - 20

local current_offer = 0
local player_case = nil
local show_values = false
local cases_to_pick = 7
local offer_index = 1

local cases = {}

local case_manager = {
    t = 90,
    cover_num = 0,
    inside_num = 0,
    update = function(self)
        if self.t < 90 then
            self.t = self.t + 1
        end
        if self.t >= 90 then
            if cases_to_pick == 0 and round <= 8 then
                game_state = GAMESTATES.offer
                offer_index = 1
                top_bar:set_text("Banker's Offer")
                current_offer = get_offer()
            else
                if round <= 8 then
                    game_state = GAMESTATES.pick_case
                elseif round == 9 then
                    game_state = GAMESTATES.game_over
                end
            end
        end
    end,
    reset = function(self, case)
        self.t = 0
        self.cover_num = case.number
        self.inside_num = case.value
    end,
}

local case_spots = {
    { 0, 0 }, { 0, 1 }, { 0, 2 }, { 0, 3 }, { 0, 4 }, { 0, 5 },
    { 1, 0 }, { 1, 1 }, { 1, 2 }, { 1, 3 }, { 1, 4 }, { 1, 5 },
    { 2, 0 }, { 2, 1 }, { 2, 2 }, { 2, 3 }, { 2, 4 }, { 2, 5 },
    { 3, 0 }, { 3, 1 }, { 3, 2 }, { 3, 3 }, { 3, 4 }, { 3, 5 }
}


local case_pos = {
    { x = col_1, y = row_1_y },
    { x = col_2, y = row_1_y },
    { x = col_3, y = row_1_y },
    { x = col_4, y = row_1_y },
    { x = col_5, y = row_1_y },
    { x = col_6, y = row_1_y },

    { x = col_1, y = row_2_y },
    { x = col_2, y = row_2_y },
    { x = col_3, y = row_2_y },
    { x = col_4, y = row_2_y },
    { x = col_5, y = row_2_y },
    { x = col_6, y = row_2_y },

    { x = col_1, y = row_3_y },
    { x = col_2, y = row_3_y },
    { x = col_3, y = row_3_y },
    { x = col_4, y = row_3_y },
    { x = col_5, y = row_3_y },
    { x = col_6, y = row_3_y },

    { x = col_1, y = row_4_y },
    { x = col_2, y = row_4_y },
    { x = col_3, y = row_4_y },
    { x = col_4, y = row_4_y },
    { x = col_5, y = row_4_y },
    { x = col_6, y = row_4_y },
}

local button = {}
button.__index = button

function button.new(str, pos, callback, col, idx)
    local _b = setmetatable({}, button)
    _b.text = str
    _b.x = pos[1]
    _b.y = pos[2]
    _b.w = 50
    _b.h = 50
    _b.callback = callback
    _b.b_color = 1
    _b.color = col
    _b.hovered = false
    _b.index = idx
    return _b
end

function button:update()
    self.is_hovered = self.index == offer_index
end

function button:get_value()
    return self.value
end

function button:was_clicked()
    self:callback()
end

function button:draw()
    rect(self.x, self.y, self.w, self.h, self.color)
    if self.callback == accept_deal then
        print(self.text, self.x + 8, self.y + 22, 12)
    else
        print(self.text, self.x + 8, self.y + 22, 12)
    end
    if self.is_hovered then
        rectb(self.x, self.y, self.w, self.h, 12)
    end
end

function show_case_value(c)
    print("Case " .. c.cover_num .. " had", 185, 40, FONT_COLOR, false, 1, true)
    print(c.inside_num, 185, 40, 11, FONT_COLOR)
end

local case = {}
case.__index = case

function case.new(num, value, pos, spot)
    local _c = setmetatable({}, case)
    _c.number = num
    _c.value = value
    _c.x = pos.x
    _c.y = pos.y
    _c.home_x = pos.x
    _c.home_y = pos.y
    _c.w = 20
    _c.h = 15
    _c.hovered = false
    _c.picked = false
    _c.spot = spot
    _c.ghost_mode = false
    _c.move_t = 0
    _c.move_p = 0
    _c.end_loc = { 200, 60 }
    if num <= 9 then
        _c.txt_pos = { _c.x + 8, _c.y + 6 }
    else
        _c.txt_pos = { _c.x + 5, _c.y + 6 }
    end
    return _c
end

function case:update()
    self.is_hovered = self.spot[1] == selector_index[1] and self.spot[2] == selector_index[2]
    if self.move_p < self.move_t then
        self.move_p = self.move_p + 1
        self.x = lerp(self.x, self.end_loc[1], self.move_p / self.move_t)
        self.y = lerp(self.y, self.end_loc[2], self.move_p / self.move_t)

        if self.number <= 9 then
            self.txt_pos = { self.x + 8, self.y + 6 }
        else
            self.txt_pos = { self.x + 5, self.y + 6 }
        end

        if self.x == self.end_loc[1] and self.y == self.end_loc[2] then
            self.ghost_mode = true
            can_player_input = true
        end
    end
end

function case:was_clicked()
    can_player_input = false
    self.move_t = 120
    self.picked = true
    if player_case == nil then
        player_case = self
        goto_next_round()
        return
    end

    cases_to_pick = clamp(0, cases_to_pick - 1, 6)

    open_case(self)
end

function case:draw()
    if not self.ghost_mode then
        rect(self.x, self.y, 20, 15, 14)
        if self.is_hovered then
            rectb(self.x, self.y, 20, 15, 4)
            print(self.number, self.txt_pos[1], self.txt_pos[2], 4)
        else
            rectb(self.x, self.y, 20, 15, 13)
            print(self.number, self.txt_pos[1], self.txt_pos[2], 13)
        end
    else
        if self.is_hovered then
            rectb(self.home_x, self.home_y, 20, 15, 4)
        else
            rectb(self.home_x, self.home_y, 20, 15, 14)
        end
    end
end

function open_case(c)
    can_player_input = false
    case_manager:reset(c)
    update_game_value(c.value, false)
end

local case_values = {
    1,
    3,
    5,
    10,
    25,
    50,
    75,
    100,
    200,
    250,
    500,
    750,
    1000,
    2500,
    5000,
    10000,
    25000,
    50000,
    100000,
    250000,
    500000,
    750000,
    900000,
    1000000
}


local game_values = {
    { value = 1,       in_play = true },
    { value = 3,       in_play = true },
    { value = 5,       in_play = true },
    { value = 10,      in_play = true },
    { value = 25,      in_play = true },
    { value = 50,      in_play = true },
    { value = 75,      in_play = true },
    { value = 100,     in_play = true },
    { value = 200,     in_play = true },
    { value = 250,     in_play = true },
    { value = 500,     in_play = true },
    { value = 750,     in_play = true },
    { value = 1000,    in_play = true },
    { value = 2500,    in_play = true },
    { value = 5000,    in_play = true },
    { value = 10000,   in_play = true },
    { value = 25000,   in_play = true },
    { value = 50000,   in_play = true },
    { value = 100000,  in_play = true },
    { value = 250000,  in_play = true },
    { value = 500000,  in_play = true },
    { value = 750000,  in_play = true },
    { value = 900000,  in_play = true },
    { value = 1000000, in_play = true }
}


function reset_game()
    game_state = GAMESTATES.title
    offer_index = 1
    round = 0
    cases_to_pick = 7
    player_case = nil
    for k, v in ipairs(game_values) do
        game_values[k].in_play = true
    end
end

function get_offer()
    local offer
    local values_left = 0
    local sum = 0
    local off_set = 0.50
    for _, v in ipairs(game_values) do
        if v.in_play then
            values_left = values_left + 1
            sum = sum + v.value
        end
    end
    offer = math.floor((sum / values_left) * off_set)
    return offer
end

function update_game_value(value, in_play)
    for _, v in ipairs(game_values) do
        if v.value == value then
            v.in_play = in_play
            break
        end
    end
end

function shuffle(t)
    for i = #t, 1, -1 do
        local j = math.floor(math.random(i)) + 1
        t[i], t[j] = t[j], t[i]
    end
end

function goto_next_round()
    round = round + 1
    cases_to_pick = please_rename[round]
    update_topbar(cases_to_pick)
    if round < 9 then
        game_state = GAMESTATES.pick_case
    end
end

function setup_cases()
    cases = {}
    shuffle(case_values)
    for i = 1, 24 do
        table.insert(cases, case.new(i, case_values[i], case_pos[i], case_spots[i]))
    end
end

function start_game()
    setup_cases()
    top_bar:set_text("Pick your case")
    game_state = GAMESTATES.pick_case
end

function accept_deal()
    game_state = GAMESTATES.deal_accepted
end

function reject_deal()
    if round < 7 then
        goto_next_round()
    else
        game_state = GAMESTATES.game_over
        round = round + 1
        for _, c in ipairs(cases) do
            if c.picked == false then
                trace("last case #: " .. c.number .. ". This is round: " .. round)
                last_case = c
            end
        end
    end
end

local btn_deal = button.new("ACCEPT", { 20, 50 }, accept_deal, 6, 1)
local btn_no_deal = button.new("REJECT", { 95, 50 }, reject_deal, 2, 2)

function TIC()
    _UPDATE()
    _DRAW()
end

function _UPDATE()
    if game_state == GAMESTATES.pick_case or
        game_state == GAMESTATES.offer then
        show_values = btn(6)
    end

    top_bar:update()

    if game_state == GAMESTATES.title then
        update_title()
    elseif game_state == GAMESTATES.pick_case then
        update_pick_case()
    elseif game_state == GAMESTATES.offer then
        update_offer()
    elseif game_state == GAMESTATES.deal_accepted then
        update_deal_accepted()
    elseif game_state == GAMESTATES.game_over then
        update_game_over()
    end
end

function _DRAW()
    cls(0)

    if game_state == GAMESTATES.title then
        draw_title()
    elseif game_state == GAMESTATES.pick_case then
        draw_pick_case()
        draw_border()
    elseif game_state == GAMESTATES.offer then
        draw_offer()
        draw_border()
    elseif game_state == GAMESTATES.deal_accepted then
        draw_deal_accepted()
    elseif game_state == GAMESTATES.game_over then
        draw_game_over()
    end

    if show_values then
        draw_display_values()
    end

    if game_state == GAMESTATES.pick_case or
        game_state == GAMESTATES.offer then
        if not show_values then
            print("Press Z to select", 3, 120, FONT_COLOR, false, 1, true)
            print("Hold A to see remaining", 3, 128, FONT_COLOR, false, 1, true)
            if player_case then
                print("Your Case: " .. player_case.number, 110, 128, FONT_COLOR, false, 1, true)
            end
        end
    end
end

function update_title()
    if btnp(5) then -- Gamepad (B)
        start_game()
    end
end

function update_pick_case()
    case_manager:update()
    if can_player_input and not show_values then
        if btnp(0) then
            move_selector("up")
        elseif btnp(1) then
            move_selector("down")
        elseif btnp(2) then
            move_selector("left")
        elseif btnp(3) then
            move_selector("right")
        end

        if btnp(4) and not show_values then -- Gamepad (A)
            for b in all(cases) do
                if not b.picked and b.is_hovered then
                    can_player_input = false
                    b:was_clicked()
                    update_topbar(cases_to_pick)
                end
            end
        end
    end

    for b in all(cases) do
        b:update()
    end
end

function update_offer()
    btn_deal:update()
    btn_no_deal:update()

    if btnp(2) then
        offer_index = clamp(1, offer_index - 1, 2)
    elseif btnp(3) then
        offer_index = clamp(1, offer_index + 1, 2)
    end

    if btnp(4) and not show_values then -- Gamepad (A)
        for b in all({ btn_deal, btn_no_deal }) do
            b:update()
            if b.is_hovered then
                b:was_clicked()
            end
        end
    end
end

function is_valid_spot(x, y)
    for _, c in ipairs(cases) do
        if not c.picked and c.spot[1] == x and c.spot[2] == y then
            return true
        end
    end
    return false
end

function update_topbar(n_cases)
    local _txt = ""
    if player_case then
        if round < 1 then
            _txt = "Pick " .. n_cases .. " more cases"
        else
            _txt = "Pick " .. n_cases .. " case"
        end
    else
        _txt = "Pick your case"
    end
    top_bar:set_text(_txt)
end

function move_selector(dir)
    if dir == "up" then
        selector_index[1] = clamp(0, selector_index[1] - 1, 4)
    elseif dir == "down" then
        selector_index[1] = clamp(0, selector_index[1] + 1, 3)
    elseif dir == "left" then
        selector_index[2] = clamp(0, selector_index[2] - 1, 5)
    elseif dir == "right" then
        selector_index[2] = clamp(0, selector_index[2] + 1, 5)
    end
end

function update_deal_accepted()
    if btnp(5) then
        reset_game()
    end
end

function update_game_over()
    if btnp(5) then
        reset_game()
    end
end

function draw_border()
    top_bar:draw()
    line(0, 8, 240, 8, BORDER_COLOR)
    line(0, 135, 240, 135, BORDER_COLOR)
    line(0, 0, 240, 0, BORDER_COLOR)
    line(0, 0, 0, 134, BORDER_COLOR)
    line(164, 8, 164, 134, BORDER_COLOR)
    line(239, 0, 239, 134, BORDER_COLOR)
end

function draw_title()
    print("Accept", 50, 42, FONT_COLOR, true, 2)
    print("or", 80, 56, FONT_COLOR, false, 2)
    print("Reject", 90, 72, FONT_COLOR, false, 2)
    print("Press X to play", 70, 110, FONT_COLOR)
end

function draw_pick_case()
    for _, r in ipairs(cases) do
        if not r.picked or 4 == 4 then
            r:draw()
        end
    end

    if case_manager.t < 90 then
        print("Case " .. case_manager.cover_num .. " had", 185, 40, FONT_COLOR, false, 1, true)
        print("$" .. comma_value(case_manager.inside_num), 185, 50, FONT_COLOR, false, 1, true) --, false, 1, true)
    end
end

function draw_display_values()
    local _start_y = 15
    rect(165, 9, 74, 126, 0)


    for i = 1, 12 do
        if game_values[i].in_play then
            col = 12
        else
            col = 15
        end
        print("$ " .. comma_value(game_values[i].value), 50 + 123, _start_y + (i - 1) * 8, col, false, 1, true)
    end

    for i2 = 1, 12 do
        if game_values[i2 + 12].in_play then
            col = 12
        else
            col = 15
        end
        print("$ " .. comma_value(game_values[i2 + 12].value), 72 + 123, _start_y + (i2 - 1) * 8, col, false, 1, true)
    end
end

function draw_offer()
    if round == 7 then
        print("LAST OFFER", 56, 20, FONT_COLOR)
    end
    print("Offer: $" .. comma_value(current_offer), 56, 30, FONT_COLOR)
    btn_deal:draw()
    btn_no_deal:draw()
end

function draw_game_over()
    print("You turned down all offers", 60, 30, FONT_COLOR)
    print("Your Case Value", 60, 45, FONT_COLOR)
    print("$" .. comma_value(player_case.value), 60, 58, FONT_COLOR)
    print("X to reset", 60, 120, FONT_COLOR)
end

function draw_deal_accepted()
    print("You accepted", 60, 30, FONT_COLOR)
    print("$" .. comma_value(current_offer), 60, 38, FONT_COLOR)
    print("Your case had", 60, 50, FONT_COLOR)
    print("$" .. comma_value(player_case.value), 60, 58, FONT_COLOR)

    if current_offer > player_case.value then
        print("Well played", 60, 100, FONT_COLOR)
    else
        print("Better luck next time", 60, 100, FONT_COLOR)
    end

    print("X to reset", 60, 120, FONT_COLOR)
end

function all(tbl)
    local i = 0
    return function()
        i = i + 1; return tbl[i]
    end
end

function comma_value(amount)
    local formatted = amount
    local _k = nil
    while true do
        formatted, _k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if (_k == 0) then
            break
        end
    end
    return formatted
end

function clamp(low, n, high)
    return math.min(math.max(n, low), high)
end

function lerp(a, b, t)
    return a + (b - a) * t
end

function del(t, a)
    for i, v in ipairs(t) do
        if v == a then
            t[i] = t[#t]
            t[#t] = nil
            return
        end
    end
end

-- <SPRITES>
-- 001:c000000c0c0000c000c00c00000cc000000cc00000c00c000c0000c0c000000c
-- </SPRITES>

-- <WAVES>
-- 000:00000000ffffffff00000000ffffffff
-- 001:0123456789abcdeffedcba9876543210
-- 002:0123456789abcdef0123456789abcdef
-- 003:22222222222000000666666666bbbbbb
-- </WAVES>

-- <SFX>
-- 000:01000100010001000100010001000100010001000100010001000100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100304000000000
-- 002:03500380f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300304000000000
-- 003:500050d050c060a0609070909080a080909070a060e0f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000000000000000
-- </SFX>

-- <TRACKS>
-- 000:100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </TRACKS>

-- <SCREEN>
-- 000:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 001:c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c
-- 002:c0000000000000000000000000000000000000444400440000000440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c
-- 003:c0000000000000000000000000000000000000440040000044440440040000040044004440044004044440000000444400444400444400444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c
-- 004:c0000000000000000000000000000000000000440040440444000444400000040044044004044004044004000004440004004404440004404400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c
-- 005:c0000000000000000000000000000000000000444400440444000440040000004444044004044004044000000004440004004400044404440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c
-- 006:c0000000000000000000000000000000000000440000440044440440040000000044004440004440044000000000444400444404444000444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c
-- 007:c0000000000000000000000000000000000000000000000000000000000000004440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c
-- 008:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 009:c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 010:c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 011:c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 012:c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 013:c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 014:c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 015:c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 016:c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 017:c0000000004444444444444444444400000dddddddddddddddddddd00000dddddddddddddddddddd00000dddddddddddddddddddd00000dddddddddddddddddddd00000dddddddddddddddddddd000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 018:c0000000004eeeeeeeeeeeeeeeeee400000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 019:c0000000004eeeeeeeeeeeeeeeeee400000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 020:c0000000004eeeeeeeeeeeeeeeeee400000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 021:c0000000004eeeeeeeeeeeeeeeeee400000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 022:c0000000004eeeeeeeeeeeeeeeeee400000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 023:c0000000004eeeeeeee44eeeeeeee400000deeeeeeeddddeeeeeeed00000deeeeeeedddddeeeeeed00000deeeeeeeeeddeeeeeeed00000deeeeeeedddddeeeeeed00000deeeeeeeedddeeeeeeed000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 024:c0000000004eeeeeee444eeeeeeee400000deeeeeeeeeeddeeeeeed00000deeeeeeeeeeddeeeeeed00000deeeeeeeedddeeeeeeed00000deeeeeeeddeeeeeeeeed00000deeeeeeeddeeeeeeeeed000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 025:c0000000004eeeeeeee44eeeeeeee400000deeeeeeeedddeeeeeeed00000deeeeeeeeeddeeeeeeed00000deeeeeeeddedeeeeeeed00000deeeeeeeddddeeeeeeed00000deeeeeeeddddeeeeeeed000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 026:c0000000004eeeeeeee44eeeeeeee400000deeeeeeeddeeeeeeeeed00000deeeeeeedeeddeeeeeed00000deeeeeeedddddeeeeeed00000deeeeeeeeeeddeeeeeed00000deeeeeeeddeedeeeeeed000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 027:c0000000004eeeeeee4444eeeeeee400000deeeeeeedddddeeeeeed00000deeeeeeeedddeeeeeeed00000deeeeeeeeeedeeeeeeed00000deeeeeeeddddeeeeeeed00000deeeeeeeedddeeeeeeed000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 028:c0000000004eeeeeeeeeeeeeeeeee400000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 029:c0000000004eeeeeeeeeeeeeeeeee400000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 030:c0000000004eeeeeeeeeeeeeeeeee400000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 031:c0000000004444444444444444444400000dddddddddddddddddddd00000dddddddddddddddddddd00000dddddddddddddddddddd00000dddddddddddddddddddd00000dddddddddddddddddddd000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 032:c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 033:c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 034:c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 035:c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 036:c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 037:c000000000dddddddddddddddddddd00000dddddddddddddddddddd00000dddddddddddddddddddd00000dddddddddddddddddddd00000dddddddddddddddddddd00000dddddddddddddddddddd000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 038:c000000000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 039:c000000000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 040:c000000000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 041:c000000000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 042:c000000000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 043:c000000000deeeeeeedddddeeeeeed00000deeeeeeeedddeeeeeeed00000deeeeeeeedddeeeeeeed00000deeeeeddeeedddeeeeed00000deeeeeddeeeddeeeeeed00000deeeeeddeeddddeeeeed000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 044:c000000000deeeeeeeeeeddeeeeeed00000deeeeeeeddeedeeeeeed00000deeeeeeeddeedeeeeeed00000deeeedddeeddeddeeeed00000deeeedddeedddeeeeeed00000deeeedddeeeeeddeeeed000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 045:c000000000deeeeeeeeeddeeeeeeed00000deeeeeeeedddeeeeeeed00000deeeeeeeeddddeeeeeed00000deeeeeddeedddedeeeed00000deeeeeddeeeddeeeeeed00000deeeeeddeeedddeeeeed000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 046:c000000000deeeeeeeeddeeeeeeeed00000deeeeeeeddeedeeeeeed00000deeeeeeeeeeedeeeeeed00000deeeeeddeeddeedeeeed00000deeeeeddeeeddeeeeeed00000deeeeeddeeddeeeeeeed000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 047:c000000000deeeeeeeddeeeeeeeeed00000deeeeeeeedddeeeeeeed00000deeeeeeeedddeeeeeeed00000deeeeddddeedddeeeeed00000deeeeddddeddddeeeeed00000deeeeddddedddddeeeed000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 048:c000000000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 049:c000000000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 050:c000000000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 051:c000000000dddddddddddddddddddd00000dddddddddddddddddddd00000dddddddddddddddddddd00000dddddddddddddddddddd00000dddddddddddddddddddd00000dddddddddddddddddddd000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 052:c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 053:c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 054:c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 055:c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 056:c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 057:c000000000dddddddddddddddddddd00000dddddddddddddddddddd00000dddddddddddddddddddd00000dddddddddddddddddddd00000dddddddddddddddddddd00000dddddddddddddddddddd000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 058:c000000000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 059:c000000000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 060:c000000000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 061:c000000000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 062:c000000000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 063:c000000000deeeeeddeedddddeeeed00000deeeeeddeeeeddeeeeed00000deeeeeddeedddddeeeed00000deeeeeddeeedddeeeeed00000deeeeeddeedddddeeeed00000deeeeeddeeedddeeeeed000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 064:c000000000deeeedddeeeeeddeeeed00000deeeedddeeedddeeeeed00000deeeedddeeddeeeeeeed00000deeeedddeeddeeeeeeed00000deeeedddeeeeeddeeeed00000deeeedddeeddeedeeeed000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 065:c000000000deeeeeddeeeeddeeeeed00000deeeeeddeeddedeeeeed00000deeeeeddeeddddeeeeed00000deeeeeddeeddddeeeeed00000deeeeeddeeeeddeeeeed00000deeeeeddeeedddeeeeed000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 066:c000000000deeeeeddeedeeddeeeed00000deeeeeddeedddddeeeed00000deeeeeddeeeeeddeeeed00000deeeeeddeeddeedeeeed00000deeeeeddeeeddeeeeeed00000deeeeeddeeddeedeeeed000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 067:c000000000deeeeddddeedddeeeeed00000deeeeddddeeeedeeeeed00000deeeeddddeddddeeeeed00000deeeeddddeedddeeeeed00000deeeeddddeddeeeeeeed00000deeeeddddeedddeeeeed000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 068:c000000000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 069:c000000000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 070:c000000000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 071:c000000000dddddddddddddddddddd00000dddddddddddddddddddd00000dddddddddddddddddddd00000dddddddddddddddddddd00000dddddddddddddddddddd00000dddddddddddddddddddd000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 072:c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 073:c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 074:c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 075:c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 076:c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 077:c000000000dddddddddddddddddddd00000dddddddddddddddddddd00000dddddddddddddddddddd00000dddddddddddddddddddd00000dddddddddddddddddddd00000dddddddddddddddddddd000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 078:c000000000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 079:c000000000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 080:c000000000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 081:c000000000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 082:c000000000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 083:c000000000deeeeeddeeedddeeeeed00000deeeeddddeeedddeeeed00000deeeeddddeeeddeeeeed00000deeeeddddeeddddeeeed00000deeeeddddeedddddeeed00000deeeeddddeeeeddeeeed000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 084:c000000000deeeedddeeddeedeeeed00000deeeeeeeddeddeddeeed00000deeeeeeeddedddeeeeed00000deeeeeeeddeeeeddeeed00000deeeeeeeddeeeeddeeed00000deeeeeeeddeedddeeeed000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 085:c000000000deeeeeddeeeddddeeeed00000deeeeedddeedddedeeed00000deeeeedddeeeddeeeeed00000deeeeedddeeedddeeeed00000deeeeedddeeeeddeeeed00000deeeeedddeeddedeeeed000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 086:c000000000deeeeeddeeeeeedeeeed00000deeeeddeeeeddeedeeed00000deeeeddeeeeeddeeeeed00000deeeeddeeeeddeeeeeed00000deeeeddeeeedeeddeeed00000deeeeddeeeedddddeeed000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 087:c000000000deeeeddddeedddeeeeed00000deeeedddddeedddeeeed00000deeeedddddeddddeeeed00000deeeedddddedddddeeed00000deeeedddddeedddeeeed00000deeeedddddeeeedeeeed000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 088:c000000000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 089:c000000000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 090:c000000000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed00000deeeeeeeeeeeeeeeeeed000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 091:c000000000dddddddddddddddddddd00000dddddddddddddddddddd00000dddddddddddddddddddd00000dddddddddddddddddddd00000dddddddddddddddddddd00000dddddddddddddddddddd000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 092:c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 093:c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 094:c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 095:c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 096:c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 097:c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 098:c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 099:c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 100:c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 101:c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 102:c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 103:c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 104:c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 105:c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 106:c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 107:c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 108:c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 109:c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 110:c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 111:c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 112:c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 113:c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 114:c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 115:c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 116:c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 117:c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 118:c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 119:c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 120:c0044000000000000000000000400000400000000000000004400000000000400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 121:c0040404040044004400440004040004440040000044004400400044004404440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 122:c0044004400404044004400004440000400404000440040400400404040000400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 123:c0040004000440000400040004040000400404000004044000400440040000400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 124:c0040004000044044004400004040000040040000440004404440044004400040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 125:c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 126:c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 127:c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 128:c0040400000440000400040400004000000000000000000000000000000000000004000004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 129:c0040400400040004400040400044400400000440044004400040400440444044000044000044000440000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 130:c0044404040040040400004000004004040004400404040400044004040444004404040404040404040000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 131:c0040404040040040400040400004004040000040440044000040004400404040404040404040404440000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 132:c0040400400444004400040400000400400004400044004400040000440404044404040404040400040000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 133:c0000000000000000000000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 134:c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000000000000000c
-- 135:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- </SCREEN>

-- <PALETTE>
-- 000:1a1c2c5d275db13e53ef7d57ffcd75a7f07038b76425717929366f3b5dc941a6f673eff7f4f4f494b0c2566c86333c57
-- </PALETTE>

