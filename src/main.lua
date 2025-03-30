
function _init()
    FONT_COLOR = 9
    PLEASE_RENAME = { 6, 5, 4, 3, 2, 1, 1, 1, 0 }
    BORDER_COLOR = 12
    GAMESTATES = {
        title = 0,
        pick_case = 1,
        display_values = 2,
        offer = 3,
        game_over = 5,
        deal_accepted = 6
    }

    --TODO: Remove math
    --TODO: Make constants to uppercase
    START_Y = 18
    row_1_y = 15 + 16
    row_2_y = 35 + 16
    row_3_y = 55 + 16
    row_4_y = 75 + 16

    COL_1 = 5
    col_2 = 30
    col_3 = 55
    col_4 = 105 - 25
    col_5 = 130 - 25
    col_6 = 155 - 25


    case_pos = {
        { x = COL_1, y = row_1_y },
        { x = col_2, y = row_1_y },
        { x = col_3, y = row_1_y },
        { x = col_4, y = row_1_y },
        { x = col_5, y = row_1_y },
        { x = col_6, y = row_1_y },

        { x = COL_1, y = row_2_y },
        { x = col_2, y = row_2_y },
        { x = col_3, y = row_2_y },
        { x = col_4, y = row_2_y },
        { x = col_5, y = row_2_y },
        { x = col_6, y = row_2_y },

        { x = COL_1, y = row_3_y },
        { x = col_2, y = row_3_y },
        { x = col_3, y = row_3_y },
        { x = col_4, y = row_3_y },
        { x = col_5, y = row_3_y },
        { x = col_6, y = row_3_y },

        { x = COL_1, y = row_4_y },
        { x = col_2, y = row_4_y },
        { x = col_3, y = row_4_y },
        { x = col_4, y = row_4_y },
        { x = col_5, y = row_4_y },
        { x = col_6, y = row_4_y },
    }


    case_values = {
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


    game_values = {
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



    current_offer = 0
    player_case = nil
    show_values = false
    cases_to_pick = 7
    round = 0
    last_case = nil
    can_player_click = true
    mx, my, mb = nil, nil, nil
    game_state = GAMESTATES.title
    is_case_opening = false
    btn_deal = button.new("ACCEPT", { 20, 50 }, accept_deal, 27, 1)
    btn_no_deal = button.new("REJECT", { 95, 50 }, reject_deal, 24, 2)
    offer_btns = {}
    add(offer_btns, btn_deal)
    add(offer_btns, btn_no_deal)
    vid(3)
end

function _update()
    top_bar:update()

    if not is_case_opening then
        mx, my, mb = mouse()
    end

    if mb == 1 then
        if m_delay == 0 then
            on_mouse_click(mx, my)
            m_delay = m_delay + 1
            return
        end
    else
        m_delay = 0
    end

    can_player_click = not is_case_opening

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

function _draw()
    cls()
    if game_state == GAMESTATES.title then
        draw_title()
    elseif game_state == GAMESTATES.pick_case then
        draw_pick_case()
    elseif game_state == GAMESTATES.offer then
        draw_offer()
        draw_border()
    elseif game_state == GAMESTATES.deal_accepted then
        draw_deal_accepted()
    elseif game_state == GAMESTATES.game_over then
        draw_game_over()
    end

    if not is_case_opening then
        spr(1, mx - 2, my - 2)
    end
end

function on_mouse_click(x, y)
    if is_case_opening then
        return
    end

    --notify("click on " .. x .. "," .. y)
    if game_state == GAMESTATES.title then
    elseif game_state == GAMESTATES.pick_case then
        if can_player_click then
            for c in all(cases) do
                if not c.picked and c.is_hovered then
                    can_player_click = false
                    c:was_clicked()
                    update_topbar(cases_to_pick)
                    return
                end
            end
        end
    elseif game_state == GAMESTATES.offer then
        for b in all(offer_btns) do
            if b.is_hovered then
                b:was_clicked()
                return
            end
        end
    elseif game_state == GAMESTATES.deal_accepted then
    elseif game_state == GAMESTATES.game_over then
    end
end

cases = {}

case_manager = {
    t = 80,
    cover_num = 0,
    inside_num = 0,
    update = function(self)
        is_case_opening = self.t < 80

        if self.t < 90 then
            self.t = self.t + 1
        end
        if self.t >= 90 then
            if cases_to_pick == 0 and round <= 8 then
                game_state = GAMESTATES.offer
                is_case_opening = false
                offer_index = 1
                top_bar:set_text("BANKER'S OFFER")
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
    cases_to_pick = PLEASE_RENAME[round]
    update_topbar(cases_to_pick)
    if round < 9 then
        game_state = GAMESTATES.pick_case
    end
end

function setup_cases()
    cases = {}
    shuffle(case_values)
    for i = 1, 24 do
        table.insert(cases, case.new(i, case_values[i], case_pos[i]))
    end
end

function start_game()
    setup_cases()
    top_bar:set_text("PICK YOUR CASE")
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
                notify("last case #: " .. c.number .. ". This is round: " .. round)
                last_case = c
            end
        end
    end
end

function update_title()
    if keyp("space") then
        start_game()
    end
end

function update_pick_case()
    case_manager:update()

    for c in all(cases) do
        c:update()
    end
end

function update_offer()
    btn_deal:update()
    btn_no_deal:update()
end

function update_topbar(n_cases)
    local _txt = ""
    if player_case then
        if round < 1 then
            _txt = "PICK " .. n_cases .. " MORE CASES"
        else
            _txt = "PICK " .. n_cases .. " CASE"
        end
    else
        _txt = "Pick your case"
    end
    top_bar:set_text(_txt)
end

function update_deal_accepted()
    if keyp("space") then
        reset_game()
        return
    end
end

function update_game_over()
    if keyp("space") then
        reset_game()
        return
    end
end

function draw_border()
    top_bar:draw()
    line(0, 8, 240, 8, BORDER_COLOR)
    line(0, 134, 240, 134, BORDER_COLOR)
    line(0, 0, 240, 0, BORDER_COLOR)
    line(0, 0, 0, 134, BORDER_COLOR)
    line(155, 8, 155, 155, BORDER_COLOR)
    line(239, 0, 239, 134, BORDER_COLOR)
end

function draw_title()
    print("Accept", 50, 42, FONT_COLOR)
    print("or", 80, 56, FONT_COLOR)
    print("Reject", 90, 72, FONT_COLOR)
    print("Press SPACE to play", 70, 110, FONT_COLOR)
end

function draw_pick_case()
    if is_case_opening then
        cls()
        if case_manager.t < 90 then
            print("Case " .. case_manager.cover_num .. " had", 85, 60, FONT_COLOR)
            print("$" .. comma_value(case_manager.inside_num), 85, 70, FONT_COLOR)
        end
        return
    end

    for _, r in ipairs(cases) do
        if not r.picked or 4 == 4 then
            r:draw()
        end
    end

    draw_display_values()
    draw_border()
end

function draw_display_values()
    rectfill(156, 9, 250, 133, 0)

    for i = 1, 12 do
        if game_values[i].in_play then
            col = 12
        else
            col = 5
        end
        print("$" .. comma_value(game_values[i].value), 37 + 123, START_Y + (i - 1) * 9, col)
    end

    for i2 = 1, 12 do
        if game_values[i2 + 12].in_play then
            col = 12
        else
            col = 5
        end
        print("$" .. comma_value(game_values[i2 + 12].value), 65 + 123, START_Y + (i2 - 1) * 9, col)
    end
end

function draw_offer()
    if round == 7 then
        print("LAST OFFER", 56, 20, FONT_COLOR)
    end
    print("Offer: $" .. comma_value(current_offer), 56, 30, FONT_COLOR)
    btn_deal:draw()
    btn_no_deal:draw()
    draw_display_values()
end

function draw_game_over()
    print("You turned down all offers", 60, 30, FONT_COLOR)
    print("Your Case Value", 60, 45, FONT_COLOR)
    print("$" .. comma_value(player_case.value), 60, 58, FONT_COLOR)
    print("SPACE to return to main", 60, 120, FONT_COLOR)
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

    print("SPACE to return to main", 60, 120, FONT_COLOR)
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
