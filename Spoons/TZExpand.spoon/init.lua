--- === TZExpand ===
---
--- Hotkey-driven multi-timezone expander for typed times.
--- Type "9pm" (or "9", "9:00", "9 pm PT", etc.) in any text input,
--- press the hotkey, and it expands to
---     9pm PT (12am ET / 5am GMT)
---
--- Usage:
---     hs.loadSpoon("TZExpand")
---     spoon.TZExpand:setHome("America/Los_Angeles")
---     spoon.TZExpand:setExtras({"America/New_York", "GMT"})
---     spoon.TZExpand:bindHotkey({"ctrl", "alt"}, "t")

local obj = {}
obj.__index = obj

obj.name = "TZExpand"
obj.version = "1.0.0"
obj.author = "Fernie <fernie@users.noreply.github.com>"
obj.license = "MIT - https://opensource.org/licenses/MIT"

obj.home = "America/Los_Angeles"
obj.extras = { "America/New_York", "GMT" }
obj.separator = " / "
obj.maxExtensions = 4

-- ----------------------------------------------------------------------------
-- Timezone abbreviations
-- ----------------------------------------------------------------------------

local TZ_LABEL = {
    ["America/Los_Angeles"] = "PT",
    ["America/Denver"]      = "MT",
    ["America/Chicago"]     = "CT",
    ["America/New_York"]    = "ET",
    ["America/Toronto"]     = "ET",
    ["Europe/London"]       = "GMT",
    ["GMT"]                 = "GMT",
    ["UTC"]                 = "UTC",
    ["Europe/Berlin"]       = "CET",
    ["Europe/Paris"]        = "CET",
    ["Europe/Madrid"]       = "CET",
    ["Asia/Tokyo"]          = "JST",
    ["Asia/Shanghai"]       = "CST",
    ["Asia/Kolkata"]        = "IST",
    ["Australia/Sydney"]    = "AET",
}

-- Inverse map (abbrev → canonical IANA) used when the user types "9pm PT".
local LABEL_TZ = {
    PT = "America/Los_Angeles", PST = "America/Los_Angeles", PDT = "America/Los_Angeles",
    MT = "America/Denver",      MST = "America/Denver",      MDT = "America/Denver",
    CT = "America/Chicago",     CST = "America/Chicago",     CDT = "America/Chicago",
    ET = "America/New_York",    EST = "America/New_York",    EDT = "America/New_York",
    GMT = "GMT", UTC = "UTC",
    CET = "Europe/Berlin",      CEST = "Europe/Berlin",
    JST = "Asia/Tokyo",
    IST = "Asia/Kolkata",
}

local function labelFor(tz) return TZ_LABEL[tz] or tz end

local function formatTime(h, m)
    local ampm = (h < 12) and "am" or "pm"
    local h12 = h % 12
    if h12 == 0 then h12 = 12 end
    if m == 0 then
        return string.format("%d%s", h12, ampm)
    else
        return string.format("%d:%02d%s", h12, m, ampm)
    end
end

-- ----------------------------------------------------------------------------
-- Parser
-- ----------------------------------------------------------------------------

-- Accepts: "9", "9:00", "9pm", "9 pm", "9pm PT", "9:30 pm PT", "21:30",
-- with surrounding whitespace.
local function parse(input)
    if not input then return nil end
    local s = input:gsub("^%s+", ""):gsub("%s+$", "")
    if s == "" then return nil end
    -- hour [:min] [am/pm] [tz]
    local h, m, ap, tz = s:match("^(%d%d?):?(%d?%d?)%s*([aApP]?[mM]?)%s*([%a/_%-]*)$")
    if not h then return nil end
    h = tonumber(h)
    if not h or h < 0 or h > 23 then return nil end
    m = tonumber(m) or 0
    if m < 0 or m > 59 then return nil end
    ap = (ap or ""):lower()
    if ap == "a" then ap = "am" elseif ap == "p" then ap = "pm" end

    -- Promote h to 24-hour when am/pm is provided.
    if ap == "pm" and h < 12 then h = h + 12
    elseif ap == "am" and h == 12 then h = 0 end

    if h > 23 then return nil end

    local sourceTZ = nil
    if tz and tz ~= "" then
        sourceTZ = LABEL_TZ[tz:upper()] or tz
    end
    return { hour = h, min = m, ampm = ap, sourceTZ = sourceTZ }
end

-- ----------------------------------------------------------------------------
-- Expansion
-- ----------------------------------------------------------------------------

-- Returns the wall-clock time-of-day (hour, min) in `tzTarget` of the
-- moment that is `parsed.hour:parsed.min` wall-clock today in `tzSource`.
local function convertWallclock(parsed, tzSource, tzTarget)
    if tzSource == tzTarget then return parsed.hour, parsed.min end
    -- Find a UTC unix timestamp that, when formatted in tzSource, reads
    -- as parsed.hour:parsed.min today.
    local nowUtc = os.time(os.date("!*t"))
    local todayUtc = os.date("!*t", nowUtc)
    -- Compose a candidate UTC moment using today's UTC date but the
    -- requested hour:min, then nudge by the source-tz offset.
    todayUtc.hour = parsed.hour; todayUtc.min = parsed.min; todayUtc.sec = 0
    -- os.time(table) interprets table as local time; convert via
    -- os.date "!" round-trip to treat it as UTC.
    local candidate = os.time(todayUtc)
    -- Compensate: candidate is "today H:M local"; we want "today H:M UTC".
    local localEpoch = os.time()
    local localUtcDiff = os.difftime(localEpoch, os.time(os.date("!*t", localEpoch)))
    candidate = candidate + localUtcDiff -- now candidate = today H:M UTC

    -- Subtract source-tz offset to get the absolute UTC moment.
    local function offsetOf(tz, atUtc)
        local p = io.popen(string.format("TZ=%q date -r %d '+%%z'", tz, atUtc))
        if not p then return 0 end
        local out = p:read("*l") or "+0000"; p:close()
        local sign, hh, mm = out:match("([%+%-])(%d%d)(%d%d)")
        if not sign then return 0 end
        local secs = tonumber(hh) * 3600 + tonumber(mm) * 60
        return sign == "-" and -secs or secs
    end
    local sourceOff = offsetOf(tzSource, candidate)
    local absUtc = candidate - sourceOff

    -- Format that absolute UTC moment in tzTarget.
    local p = io.popen(string.format("TZ=%q date -r %d '+%%H %%M'", tzTarget, absUtc))
    if not p then return parsed.hour, parsed.min end
    local out = p:read("*l") or ""; p:close()
    local hh, mm = out:match("(%d+)%s+(%d+)")
    return tonumber(hh) or parsed.hour, tonumber(mm) or parsed.min
end

local function expand(self, parsed)
    local sourceTZ = parsed.sourceTZ or self.home
    local home = formatTime(parsed.hour, parsed.min) .. " " .. labelFor(sourceTZ)

    local parts = {}
    -- If user explicitly named a source TZ different from home, include home first.
    if parsed.sourceTZ and parsed.sourceTZ ~= self.home then
        local h, m = convertWallclock(parsed, sourceTZ, self.home)
        table.insert(parts, formatTime(h, m) .. " " .. labelFor(self.home))
    end
    for _, tz in ipairs(self.extras) do
        if tz ~= sourceTZ then
            local h, m = convertWallclock(parsed, sourceTZ, tz)
            table.insert(parts, formatTime(h, m) .. " " .. labelFor(tz))
        end
    end

    if #parts == 0 then return home end
    return home .. " (" .. table.concat(parts, self.separator) .. ")"
end

-- ----------------------------------------------------------------------------
-- Selection capture + paste
-- ----------------------------------------------------------------------------

-- Grab the currently selected text via ⌘C. If there's no selection,
-- extend it backwards by `extensions` words first (each ⌥⇧←).
local function captureSelection(extensions)
    local pb = hs.pasteboard
    local snapshot = pb.readAllData()
    local sentinel = "\1TZEXPAND\1" -- never matches real content
    pb.setContents(sentinel)
    local beforeCount = pb.changeCount()

    if extensions > 0 then
        for _ = 1, extensions do
            hs.eventtap.keyStroke({"alt", "shift"}, "left", 0)
        end
    end
    hs.eventtap.keyStroke({"cmd"}, "c", 0)

    -- Poll for pasteboard update (up to ~250ms).
    local got = nil
    for _ = 1, 25 do
        hs.timer.usleep(10000)
        if pb.changeCount() ~= beforeCount then
            local s = pb.getContents()
            if s and s ~= sentinel then got = s end
            break
        end
    end

    -- Restore snapshot.
    if snapshot then pb.writeAllData(snapshot) else pb.clearContents() end
    return got
end

local function pasteText(text)
    local pb = hs.pasteboard
    local snapshot = pb.readAllData()
    pb.setContents(text)
    hs.eventtap.keyStroke({"cmd"}, "v", 0)
    hs.timer.doAfter(0.4, function()
        if snapshot then pb.writeAllData(snapshot) else pb.clearContents() end
    end)
end

-- ----------------------------------------------------------------------------
-- Public API
-- ----------------------------------------------------------------------------

-- Exposed for testing/debugging.
obj.parse = parse
function obj:_expand(parsed) return expand(self, parsed) end

function obj:setHome(tz) self.home = tz; return self end
function obj:setExtras(tzs) self.extras = tzs; return self end
function obj:setSeparator(sep) self.separator = sep; return self end

function obj:trigger()
    -- Try existing selection first.
    local sel = captureSelection(0)
    if sel and sel ~= "" then
        local parsed = parse(sel)
        if parsed then pasteText(expand(self, parsed)); return end
    end
    -- Grow the selection until it parses, or give up.
    for i = 1, self.maxExtensions do
        sel = captureSelection(i)
        if sel and sel ~= "" then
            local parsed = parse(sel)
            if parsed then pasteText(expand(self, parsed)); return end
        end
    end
    hs.alert.show("TZExpand: couldn't parse a time near the cursor", 1)
end

function obj:bindHotkey(mods, key)
    if self._hk then self._hk:delete() end
    self._hk = hs.hotkey.bind(mods, key, function() self:trigger() end)
    return self
end

return obj
