case = {}
case.__index = case

case_col = 6
case_hover_col = 9

function case.new(num, value, pos)
    local _c = setmetatable({}, case)
    _c.number = num
    _c.value = value
    _c.x = pos.x
    _c.y = pos.y
    _c.w = 20
    _c.open_t = 500
    _c.h = 15
    _c.hovered = false
    _c.picked = false
    _c.visable = true
    _c.move_t = 0
    _c.move_p = 121
    _c.end_loc = { 200, 60 }
    _c.col = 6
    _c.hover_col = 9

    if num <= 9 then
        _c.txt_pos = { _c.x + 8, _c.y + 6 }
    else
        _c.txt_pos = { _c.x + 5, _c.y + 6 }
    end
    return _c
end

function case:update()
    self.is_hovered = is_colliding(mx, my, self)

    if self.is_hovered then
        self.col = case_hover_col
    else
        self.col = case_col
    end



    --self.is_hovered = self.spot[1] == selector_index[1] and self.spot[2] == selector_index[2]
    --if self.move_p < self.move_t then
    --is_case_opening = true
    -- 	self.move_p = self.move_p + 1
    --self.x = lerp(self.x, self.end_loc[1], self.move_p / self.move_t)
    --self.y = lerp(self.y, self.end_loc[2], self.move_p / self.move_t)

    --if self.number <= 9 then
    --  self.txt_pos = { self.x + 8, self.y + 6 }
    --else
    --  self.txt_pos = { self.x + 5, self.y + 6 }
    --end

    --if self.x == self.end_loc[1] and self.y == self.end_loc[2] then

    --is_case_opening = false
    --todo: prevent player from clicking a new case before current is ready
    -- can_player_input = true
    --can_player_click = true
    --end
    -- end
end

function case:was_clicked()
    --can_player_input = false

    --self.move_t = 120
    --self.open_t = 0
    --self.move_p = 0
    self.picked = true
    if player_case == nil then
        player_case = self
        goto_next_round()
        self.update = function(self) end -- prevent checkinh for mouse
        self.col = 12
        sfx(0)
        return
    else
        self.visable = false
    end
    --open_case(self)
    cases_to_pick = clamp(0, cases_to_pick - 1, 6)
    case_manager:reset(self)
    update_game_value(self.value, false)
end

function case:draw()
    if self.visable then
        rect(self.x, self.y, self.x + 20, self.y + 15, self.col)
        print(self.number, self.txt_pos[1], self.txt_pos[2], self.col)
    end
    --else
    --rect(self.x, self.y, self.x + 20, self.y + 15, 6)
    --print(self.number, self.txt_pos[1], self.txt_pos[2], 6)
    --end
    ---else
    --if self.is_hovered then
    --rect(self.home_x, self.home_y, self.home_x + 20, self.home_y + 15, 4)
    --else
    --rect(self.home_x, self.home_y, self.home_x + 20, self.home_y + 15, 14)
    --end
    --end
end

--function open_case(c)
--  can_player_input = false
-- case_manager:reset(c)
--update_game_value(c.value, false)
--end

function is_colliding(m_x, m_y, box)
    if m_x < box.x + box.w and
        m_x > box.x and
        m_y < box.y + box.h and
        m_y > box.y then
        return true
    else
        return false
    end
end
