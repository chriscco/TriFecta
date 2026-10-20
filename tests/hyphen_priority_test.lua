local processor = dofile('data/plum/lua/hyphen_priority.lua').func
local forwarded
function KeyEvent(key) return key end
local key = {
  release = function() return false end,
  ctrl = function() return false end,
  alt = function() return false end,
  super = function() return false end,
  repr = function() return 'minus' end,
}
local selected, size, menu, composing = 0, 5, true, true
local env = {engine = {
  schema = {config = {get_int = function() return size end}},
  context = {
    is_composing = function() return composing end,
    has_menu = function() return menu end,
    composition = {back = function() return {selected_index = selected} end},
  },
  process_key = function(_, event) forwarded = event end,
}}
local function check(expected)
  forwarded = nil
  assert(processor(key, env) == expected)
  assert(forwarded == (expected == 1 and 'Page_Up' or nil))
end
check(2)
selected = 4; check(2)
selected = 5; check(1)
selected = 10; check(1)
size = 9; selected = 8; check(2)
selected = 9; check(1)
size = nil; selected = 5; check(1)
size = 0; check(1)
menu = false; check(2)
menu = true; composing = false; check(2)
composing = true
for _, modifier in ipairs({'release', 'ctrl', 'alt', 'super'}) do
  key[modifier] = function() return true end
  check(2)
  key[modifier] = function() return false end
end
key.repr = function() return 'a' end
check(2)
print('hyphen priority: 15 checks passed')
