top_bar = {
    x = 0,
    y = 1,
    str = "test",
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
