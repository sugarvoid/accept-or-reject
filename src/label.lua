Label = {}
Label.__index = Label

set_draw_target(userdata("u8", 1, 1))

function Label.new(text, x, y, col)
    local l = setmetatable({}, Label)
    local _w = print(text, 0, 0)
    set_draw_target()
    l.interactive = true
    l.w = _w
    l.h = 8
    l.x = x
    l.y = y
    l.text = text
    l.col = col
    l.default_col = col
    l.hover_col = col
    l.hovered = false
    l.callback = function() error("Add a function") end
    return l
end

function Label:update()
    if is_colliding_lbl(mx, my, self) then
        self.hovered = true
        self.col = 12
    else
        self.col = self.default_col
        self.hovered = false
    end
end

function Label:do_func()
    self:callback()
end

function is_colliding_lbl(m_x, m_y, box)
    if m_x < box.x + box.w and
        m_x > box.x and
        m_y < box.y + box.h and
        m_y > box.y then
        return true
    else
        return false
    end
end

function Label:draw()
    --rect(self.x,self.y,self.x+self.w,self.y+self.h,3)
    print(self.text, self.x, self.y, self.col)
end
