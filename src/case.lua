case = {}
case.__index = case

case_col = 6
case_hover_col = 9

function case.new(num, value, pos)
    local case = setmetatable({}, case)
    case.number = num
    case.value = value
    case.x = pos.x
    case.y = pos.y
    case.w = 20
    case.open_t = 500
    case.h = 15
    case.hovered = false
    case.picked = false
    case.visable = true
    case.move_t = 0
    case.move_p = 121
    case.end_loc = { 200, 60 }
    case.col = 6
    case.hover_col = 9

    if num <= 9 then
        case.txt_pos = { case.x + 8, case.y + 6 }
    else
        case.txt_pos = { case.x + 5, case.y + 6 }
    end
    return case
end

function case:update()
    self.is_hovered = is_colliding(mx, my, self)
    if self.is_hovered then
        self.col = case_hover_col
    else
        self.col = case_col
    end
end

function case:was_clicked()
    self.picked = true
    if player_case == nil then
        player_case = self
        goto_next_round()
        -- Replace update() to prevent case from checking for mouse for the rest of game
        self.update = function(self) end
        self.col = 12
        sfx(0)
        return
    else
        self.visable = false
    end
    cases_to_pick = clamp(0, cases_to_pick - 1, 6)
    case_manager:reset(self)
    update_game_value(self.value, false)
end

function case:draw()
    if self.visable then
        rect(self.x, self.y, self.x + 20, self.y + 15, self.col)
        print(self.number, self.txt_pos[1], self.txt_pos[2], self.col)
    end
end

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
