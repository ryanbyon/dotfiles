-- https://github.com/windwp/nvim-autopairs

local npairs = require('nvim-autopairs')
local rule = require('nvim-autopairs.rule')
local cond = require('nvim-autopairs.conds')
local utils = require('nvim-autopairs.utils')
local cmp_autopairs = require("nvim-autopairs.completion.cmp")

npairs.setup {
  check_ts = true
}

-- require nvim-cmp plugin
local cmp = require("cmp")
cmp.event:on(
  "confirm_done",
  cmp_autopairs.on_confirm_done()
)

local function multiline_close_jump(open, close)
  return rule(close, '')
      :with_pair(function()
        local row, col = utils.get_cursor()
        local line = utils.text_get_current_line()

        if #line ~= col then --not at EOL
          return false
        end

        local unclosed_count = 0
        for c in line:gmatch("[\\" .. open .. "\\" .. close .. "]") do
          if c == open then unclosed_count = unclosed_count + 1 end
          if unclosed_count > 0 and c == close then unclosed_count = unclosed_count - 1 end
        end
        if unclosed_count > 0 then return false end

        local nextrow = row + 1
        if nextrow < vim.api.nvim_buf_line_count(0)
            and vim.regex("^\\s*" .. close):match_line(0, nextrow) then
          return true
        end
        return false
      end)
      :with_move(cond.none())
      :with_cr(cond.none())
      :with_del(cond.none())
      :set_end_pair_length(0)
      :replace_endpair(function()
        return '<esc>xEa'
      end)
end

npairs.add_rules {
  multiline_close_jump("(", ")"),
  multiline_close_jump("[", "]"),
  multiline_close_jump("{", "}"),
}
