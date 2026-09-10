-- hyphen_priority.lua
-- "-" 键在组字过程中有两种冲突的含义：
--   1) key_binder 把它绑定为翻到候选词上一页（when: has_menu）
--   2) recognizer 的 "hyphenated" 规则把它识别成标识符里的字面连字符（如 "bss-service"）
-- recognizer 在处理器链中排在 key_binder 之前，且它的正则匹配完全不看当前是否已经
-- 有候选词菜单，所以只要正则匹配上就会直接抢占按键，导致候选词翻页失效——包括正常
-- 拼音组字、菜单里有很多候选词、想按"-"翻回上一页的最常见场景。
--
-- 这里把这个判断挪到 recognizer 之前：如果当前有候选词菜单，就把"-"转发成
-- Page_Up（复现 key_binder 原本的行为）；否则放行，交给 recognizer 识别成
-- 字面量，配合 hyphenated 规则输出真正的连字符。
--
-- 用法（schema）：engine/processors 里把
--   - lua_processor@*hyphen_priority
-- 加在 recognizer 之前。

local kAccepted = 1
local kNoop = 2

local function hyphen_priority(key_event, env)
  if key_event:release() or key_event:ctrl() or key_event:alt() or key_event:super() then
    return kNoop
  end
  if key_event:repr() ~= "minus" then
    return kNoop
  end
  local ctx = env.engine.context
  if ctx:is_composing() and ctx:has_menu() then
    env.engine:process_key(KeyEvent("Page_Up"))
    return kAccepted
  end
  return kNoop
end

return { func = hyphen_priority }
