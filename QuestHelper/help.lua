QuestHelper_File["help.lua"] = "0.95"
QuestHelper_Loadtime["help.lua"] = GetTime()

function QuestHelper:scaleString(val)
  return self:HighlightText(math.floor(val*100+0.5).."%")
end

function QuestHelper:genericSetScale(varname, name, mn, mx, input, onchange, ...)
  if input == "" then
    self:TextOut(string.format("Current %s scale is %s.", name, self:scaleString(QuestHelper_Pref[varname])))
  else
    local scale = tonumber(input)
    
    if not scale then
      local x = string.match(input or "", "^%s*([%d%.]+)%s*%%%s*$")
      scale = tonumber(x) or 0
      if not scale then
        self:TextOut("I don't know how to interpret your input.")
        return
      end
      scale = scale * 0.01
    end
    
    if scale < mn then
      self:TextOut(string.format("I won't accept a scale less than %s.", self:scaleString(mn)))
    elseif scale > mx then
      self:TextOut(string.format("I won't accept a scale more than %s.", self:scaleString(mx)))
    else
      QuestHelper_Pref[varname] = scale
      self:TextOut(string.format("Set %s scale set to %s.", name, self:scaleString(scale)))
      if onchange then
        onchange(...)
      end
    end
  end
end

function QuestHelper:TrackerScale(scale)
  QuestHelper:genericSetScale("track_scale", "tracker scale", .5, 2, scale,
                              function() QuestHelper.tracker:SetScale(QuestHelper_Pref.track_scale) end)
end

function QuestHelper:SetLocale(loc)
  if not loc or loc == "" then
    self:TextOut(QHText("LOCALE_LIST_BEGIN"))
    for loc, tbl in pairs(QuestHelper_Translations) do
      self:TextOut(string.format("  %s%s %s", self:HighlightText(loc),
                                              loc == QuestHelper_Pref.locale and " *" or "  ",
                                              tbl.LOCALE_NAME or "???"))
    end
  else
    for l, tbl in pairs(QuestHelper_Translations) do
      if string.find(string.lower(l), "^"..string.lower(loc)) or
         string.find(string.lower(tbl.LOCALE_NAME or ""), "^"..string.lower(loc)) then
        QuestHelper_Pref.locale = l
        QHFormatSetLocale(l)
        self:SetLocaleFonts()
        self:TextOut(QHFormat("LOCALE_CHANGED", l))
        return
      end
    end
    
    self:TextOut(QHFormat("LOCALE_UNKNOWN", tostring(loc) or "UNKNOWN"))
  end
end

function QuestHelper:ToggleHide()
  local current_objective = self.minimap_dodad.objective
  
  QuestHelper_Pref.hide = not QuestHelper_Pref.hide
  
  -- Desaturate the button texture if QuestHelper is disabled.
  if self.MapButton then
    -- This should always be true, but just in case...
    self.MapButton:GetNormalTexture():SetDesaturated(QuestHelper_Pref.hide)
  end
  
  if QuestHelper_Pref.hide then
    if QuestHelper_Pref.track then
      self:HideTracker()
    end
    
    self.map_overlay:Hide()
    self.minimap_dodad:SetObjective(nil)
    self.minimap_dodad.objective = current_objective
    self:TextOut("QuestHelper is now |cffff0000hidden|r.")
  else
    if QuestHelper_Pref.track then
      self:ShowTracker()
    end
    
    self.map_overlay:Show()
    self.minimap_dodad.objective = nil
    self.minimap_dodad:SetObjective(current_objective)
    self:TextOut("QuestHelper is now |cff00ff00shown|r.")
    -- WoW Will lockup inside ForceRouteUpdate, and so the UPDATING_ROUTE message won't appear until afterwards, making
    -- this message kind of redundant.
    -- self:TextOut(QHText("UPDATING_ROUTE"))
    QH_Timeslice_Bonus(20)        -- Let the corutine do some overtime...
  end
end

function QuestHelper:ToggleShare()
  QuestHelper_Pref.share = not QuestHelper_Pref.share
  if QuestHelper_Pref.share then
    if QuestHelper_Pref.solo then
      self:TextOut("Objective sharing will been |cff00ff00enabled|r when you disable solo mode.")
    else
      self:TextOut("Objective sharing has been |cff00ff00enabled|r.")
      self:EnableSharing()
    end
  else
    self:TextOut("Objective sharing has been |cffff0000disabled|r.")
    if QuestHelper_Pref.solo then
      self:TextOut("Objective sharing won't be reenabled when you disable solo mode.")
    else
      self:DisableSharing()
    end
  end
end

function QuestHelper:ToggleFlightTimes()
  QuestHelper_Pref.flight_time = not QuestHelper_Pref.flight_time
  if QuestHelper_Pref.flight_time then
    self:TextOut("The flight timer has been |cff00ff00enabled|r.")
  else
    self:TextOut("The flight timer has been |cffff0000disabled|r.")
  end
end

function QuestHelper:ToggleTrack()
  QuestHelper_Pref.track = not QuestHelper_Pref.track
  if QuestHelper_Pref.track then
    self:ShowTracker()
    self:TextOut("The quest tracker has been |cff00ff00enabled|r.")
  else
    self:HideTracker()
    self:TextOut("The quest tracker has been |cffff0000disabled|r.")
  end
end

function QuestHelper:ToggleTrackLevel()
  QuestHelper_Pref.track_level = not QuestHelper_Pref.track_level
  if QuestHelper_Pref.track_level then
    self:TextOut("Display of levels in the quest tracker has been |cff00ff00enabled|r.")
  else
    self:TextOut("Display of levels in the quest tracker has been |cffff0000disabled|r.")
  end
  self.tracker:reset()
end

function QuestHelper:ToggleTrackQColour()
  QuestHelper_Pref.track_qcolour = not QuestHelper_Pref.track_qcolour
  if QuestHelper_Pref.track_qcolour then
    self:TextOut("Colour for quest difficulty in quest tracker has been |cff00ff00enabled|r.")
  else
    self:TextOut("Colour for quest difficulty in quest tracker has been |cffff0000disabled|r.")
  end
  self.tracker:reset()
end

function QuestHelper:ToggleTrackOColour()
  QuestHelper_Pref.track_ocolour = not QuestHelper_Pref.track_ocolour
  if QuestHelper_Pref.track_ocolour then
    self:TextOut("Colour for objective progress in quest tracker has been |cff00ff00enabled|r.")
  else
    self:TextOut("Colour for objective progress in quest tracker has been |cffff0000disabled|r.")
  end
  self.tracker:reset()
end

function QuestHelper:ToggleTooltip()
  QuestHelper_Pref.tooltip = not QuestHelper_Pref.tooltip
  if QuestHelper_Pref.tooltip then
    self:TextOut("Objective tooltip information has been |cff00ff00enabled|r.")
  else
    self:TextOut("Objective tooltip information has been |cffff0000disabled|r.")
  end
end

function QuestHelper:Purgewarning()
  QuestHelper:TextOut("I would consider this a tragic loss, and would appreciate it if you sent me your saved data before going through with it.")
  QuestHelper:TextOut("Enter "..self:HighlightText("/qh nag verbose").." to check and see if you're destroying anything important.")
  QuestHelper:TextOut("See the "..self:HighlightText("How You Can Help").." section on the project website for instructions.")
end

function QuestHelper:Purge(code, force, noreload)
  if code == self.purge_code or force then
    QuestHelper_Quests = nil
    QuestHelper_Objectives = nil
    QuestHelper_FlightInstructors = nil
    QuestHelper_FlightRoutes = nil
    QuestHelper_Locale = nil
    QuestHelper_UID = nil
    QuestHelper_Version = nil
    QuestHelper_SaveVersion = nil
    
    QuestHelper_SaveDate = nil
    QuestHelper_SeenRealms = nil
    
    if not noreload then ReloadUI() end
  else
    if not self.purge_code then self.purge_code = self:CreateUID(8) end
    QuestHelper:TextOut("THIS COMMAND WILL DELETE ALL YOUR COLLECTED DATA")
    QuestHelper:Purgewarning()
    QuestHelper:TextOut("If you're sure you want to go through with this, enter: "..self:HighlightText("/qh purge "..self.purge_code))
  end
end

function QuestHelper:HardReset(code)
  if code == self.purge_code then
    self:ResetTrackerPosition() -- do this before we kill off the prefs, since it touches a pref
    QuestHelper_Pref = nil
    QuestHelper_ErrorList = nil -- BIZAM
    QuestHelper_KnownFlightRoutes = nil
    QuestHelper_Home = nil
    QuestHelper_CharVersion = nil
    self:Purge(nil, true)
  else
    if not self.purge_code then self.purge_code = self:CreateUID(8) end
    QuestHelper:TextOut("THIS COMMAND WILL DELETE ALL YOUR COLLECTED DATA AND RESET ALL YOUR PREFERENCES")
    QuestHelper:Purgewarning()
    QuestHelper:TextOut("If you're sure you want to go through with this, enter: "..self:HighlightText("/qh hardreset "..self.purge_code))
  end
end

function QuestHelper:ToggleSolo()
  QuestHelper_Pref.solo = not QuestHelper_Pref.solo
  if QuestHelper_Pref.solo then
    if QuestHelper_Pref.share then
      self:DisableSharing()
      self:TextOut("Objective sharing has been temporarly |cffff0000disabled|r.")
    end
    self:TextOut("Solo mode has been |cff00ff00enabled|r.")
  else
    self:TextOut("Solo mode has been |cffff0000disabled|r.")
    if QuestHelper_Pref.share then
      self:EnableSharing()
      self:TextOut("Objective sharing has been re|cff00ff00enabled|r.")
    end
  end
end

function QuestHelper:ToggleComm()
  if QuestHelper_Pref.comm then
    QuestHelper_Pref.comm = false
    self:TextOut("Communication display has been |cffff0000disabled|r.")
  else
    QuestHelper_Pref.comm = true
    self:TextOut("Communication display has been |cff00ff00enabled|r.")
  end
end

function QuestHelper:ToggleAnts()
  if QuestHelper_Pref.show_ants then
    QuestHelper_Pref.show_ants = false
    self:TextOut("Ant trails have been |cffff0000disabled|r.")
  else
    QuestHelper_Pref.show_ants = true
    self:TextOut("Ant trails have been |cff00ff00enabled|r.")
  end
end

function QuestHelper:LevelOffset(offset)
  local level = tonumber(offset)
  if level then
    if level > 0 then
      self:TextOut("Allowing quests up to "..self:HighlightText(level).." level"..(level==1 and " " or "s ")..self:HighlightText("above").." you.")
    elseif level < 0 then
      self:TextOut("Only allowing quests "..self:HighlightText(-level).." level"..(level==-1 and " " or "s ")..self:HighlightText("below").." you.")
    else
      self:TextOut("Only allowing quests "..self:HighlightText("at or below").." your current level.")
    end
    
    if not QuestHelper_Pref.filter_level then
      self:TextOut("Note: This won't have any effect until you turn the level filter on.")
    end
    
    if QuestHelper_Pref.level ~= level then
      QuestHelper_Pref.level = level
      self.defered_quest_scan = true
    end
  elseif offset == "" then
    if QuestHelper_Pref.level <= 0 then
      self:TextOut("Level offset is currently set to "..self:HighlightText(QuestHelper_Pref.level)..".")
    else
      self:TextOut("Level offset is currently set to "..self:HighlightText("+"..QuestHelper_Pref.level)..".")
    end
    
    if self.party_levels then for n, l in ipairs(self.party_levels) do
      self:TextOut("Your effective level in a "..self:HighlightText(n).." player quest is "..self:HighlightText(string.format("%.1f", l))..".")
    end end
    
    if QuestHelper_Pref.solo then
      self:TextOut("Peers aren't considered in your effective level, because you're playing solo.")
    end
  else
    self:TextOut("Expected a level offset.")
  end
end

function QuestHelper:Filter(input)
  input = string.upper(input)
  if input == "ZONE" then
    QuestHelper_Pref.filter_zone = not QuestHelper_Pref.filter_zone
    self:TextOut("Filter "..self:HighlightText("zone").." set to "..self:HighlightText(QuestHelper_Pref.filter_zone and "active" or "inactive")..".")
  elseif input == "DONE" then
    QuestHelper_Pref.filter_done = not QuestHelper_Pref.filter_done
    self:TextOut("Filter "..self:HighlightText("done").." set to "..self:HighlightText(QuestHelper_Pref.filter_done and "active" or "inactive")..".")
  elseif input == "LEVEL" then
    QuestHelper_Pref.filter_level = not QuestHelper_Pref.filter_level
    self:TextOut("Filter "..self:HighlightText("level").." set to "..self:HighlightText(QuestHelper_Pref.filter_level and "active" or "inactive")..".")
  elseif input == "BLOCKED" or input == "BLOCK" then
    QuestHelper_Pref.filter_blocked = not QuestHelper_Pref.filter_blocked
    self:TextOut("Filter "..self:HighlightText("blocked").." set to "..self:HighlightText(QuestHelper_Pref.filter_blocked and "active" or "inactive")..".")
  elseif input == "WATCHED" or input == "WATCH" then
    QuestHelper_Pref.filter_watched = not QuestHelper_Pref.filter_watched
    self:TextOut("Filter "..self:HighlightText("watched").." set to "..self:HighlightText(QuestHelper_Pref.filter_watched and "active" or "inactive")..".")
  elseif input == "" then
    self:TextOut("Filter "..self:HighlightText("zone")..": "..self:HighlightText(QuestHelper_Pref.filter_zone and "active" or "inactive"))
    self:TextOut("Filter "..self:HighlightText("level")..": "..self:HighlightText(QuestHelper_Pref.filter_level and "active" or "inactive"))
    self:TextOut("Filter "..self:HighlightText("done")..": "..self:HighlightText(QuestHelper_Pref.filter_done and "active" or "inactive"))
    self:TextOut("Filter "..self:HighlightText("blocked")..": "..self:HighlightText(QuestHelper_Pref.filter_blocked and "active" or "inactive"))
    self:TextOut("Filter "..self:HighlightText("watched")..": "..self:HighlightText(QuestHelper_Pref.filter_watched and "active" or "inactive"))
  else
    self:TextOut("Don't know what you want filtered, expect "..self:HighlightText("zone")..", "..self:HighlightText("done")..", "..self:HighlightText("level")..", or "..self:HighlightText("blocked")..".")
  end
end

function QuestHelper:ToggleCartWP()
  QuestHelper_Pref.cart_wp = not QuestHelper_Pref.cart_wp
  if QuestHelper_Pref.cart_wp then
    self:EnableCartographer()
    if Cartographer_Waypoints then
      if Waypoint and Waypoint.prototype then
        self:TextOut("Would use "..self:HightlightText("Cartographer Waypoints").." to show objectives, but another mod is interfering with it.")
      else
        self:TextOut("Will use "..self:HighlightText("Cartographer Waypoints").." to show objectives.")
      end
    else
      self:TextOut("Would use "..self:HighlightText("Cartographer Waypoints").." to show objectives, except it doesn't seem to be present.")
    end
  else
    self:DisableCartographer()
    self:TextOut("Won't use "..self:HighlightText("Cartographer Waypoints").." to show objectives.")
  end
end

function QuestHelper:ToggleTomTomWP()
  QuestHelper_Pref.tomtom_wp = not QuestHelper_Pref.tomtom_wp
  if QuestHelper_Pref.tomtom_wp then
    self:EnableTomTom()
    if TomTom then
      self:TextOut("Will use "..self:HighlightText("TomTom").." to show objectives.")
    else
      self:TextOut("Would use "..self:HighlightText("TomTom").." to show objectives, except it doesn't seem to be present.")
    end
  else
    self:DisableTomTom()
    self:TextOut("Won't use "..self:HighlightText("TomTom").." to show objectives.")
  end
end

function QuestHelper:WantPathingReset()
  self:TextOut("Will reset world graph.")
  self.defered_graph_reset = true
end

function QuestHelper:PrintVersion()
  self:TextOut("Version: "..self:HighlightText(GetAddOnMetadata("QuestHelper", "Version") or "Unknown"))
end

local function RecycleStatusString(fmt, usedcount, freetable, usedtable)
  local freetablecount = QuestHelper:TableSize(freetable)
  if usedtable then
    local usedtablecount = QuestHelper:TableSize(usedtable)
    return string.format(fmt, QuestHelper:ProgressString(string.format("%d/%d", usedtablecount, usedtablecount+freetablecount), ((usedtablecount+freetablecount == 0) and 1) or (1-usedtablecount/(usedtablecount+freetablecount)))) .. string.format(" (%d \"leaked\")", usedcount - usedtablecount)
  else
    return string.format(fmt, QuestHelper:ProgressString(string.format("%d/%d", usedcount, usedcount+freetablecount), ((usedcount+freetablecount == 0) and 1) or (1-usedcount/(usedcount+freetablecount))))
  end
end

function QuestHelper:Top(cmd)

  if cmd and string.find(cmd, "boot") then
    local bootv = {}
    for k, v in pairs(QuestHelper_Loadtime) do
      table.insert(bootv, {time = v, file = k})
    end
    table.sort(bootv, function (a, b) return a.time < b.time end)
    
    if string.find(cmd, "sort") then
      local boott = {}
      for i = 1, #bootv - 1 do
        table.insert(boott, {time = bootv[i + 1].time - bootv[i].time, file = bootv[i].file})
      end
      table.sort(boott, function(a, b) return a.time < b.time end)
    
      for _, v in pairs(boott) do
        QuestHelper:TextOut(string.format("%s: %f", v.file, v.time))
      end
      QuestHelper:TextOut(string.format("%s: shrug", bootv[#bootv].file))
    else
      for i = 1, #bootv do
        QuestHelper:TextOut(string.format("%f: %s", bootv[i].time - bootv[1].time, bootv[i].file))
      end
    end
  end
  
  if cmd and string.find(cmd, "recycle") then
    self:DumpTableTypeFrequencies()
    self:TextOut(RecycleStatusString("Using %s lua tables.", self.used_tables, self.free_tables, self.recycle_tabletyping))
    self:TextOut(RecycleStatusString("Using %s texture objects.", self.used_textures, self.free_textures))
    self:TextOut(RecycleStatusString("Using %s font objects.", self.used_text, self.free_text))
    self:TextOut(RecycleStatusString("Using %s frame objects.", self.used_frames, self.free_frames))
  end
  
  if cmd and string.find(cmd, "usage") then
    self:DumpTableTypeFrequencies()
  end
  
  if cmd and string.find(cmd, "cache") then
    self:DumpCacheData()
  end
  
  if cmd and string.find(cmd, "perf") then
    QH_Timeslice_DumpPerf()
  end
  
  UpdateAddOnMemoryUsage()
  
  local uncd = 0
  uncd = uncd - 1
  local uncs = ""
  if uncd > 0 then
    uncs = string.format(" (%d uncompressed IDs)", uncd)
  end
  
  self:TextOut(string.format("QuestHelper is using %dkb of RAM (%s/%s/%s/%s)%s", GetAddOnMemoryUsage("QuestHelper"), QuestHelper_local_version, QuestHelper_toc_version, GetBuildInfo(), GetLocale(), uncs))
end

function QuestHelper:ToggleMapButton()
  QuestHelper_Pref.map_button = not QuestHelper_Pref.map_button

  if QuestHelper_Pref.map_button then
    QuestHelper:InitMapButton()
    self:TextOut("Map button has been |cff00ff00enabled|r.")
  else
    QuestHelper:HideMapButton()
    self:TextOut("Map button has been |cffff0000disabled|r.  Use '/qh button' to restore it.")
  end
end

function QuestHelper:ChangeLog()
  self:ShowText(QuestHelper_ChangeLog, string.format("QuestHelper %s ChangeLog", QuestHelper_Version))
end

function QuestHelper:Submit()
  self:ShowText([[
|TInterface\AddOns\QuestHelper\Art\Upload.tga:100:300|t
Your data can't be submitted automatically, since AddOns can't interact with anything outside of World of Warcraft.

To do this would require me to create some third party software, and I don't want to include such software with QuestHelper, because that's the kind of thing that ill intended people are likely to tamper with.

World of Warcraft stores QuestHelper's data in a file named |cff40bbffQuestHelper.lua|r.

To find this file, first find the the directory you installed World of Warcraft to. In Windows, this defaults to |cff40bbffC:\Program Files\World of Warcraft|r, and on Mac, I believe this is |cff40bbff/Applications/World of Warcraft|r.

If you're using Windows Vista, Windows might protect the Program Files directory from changes, and redirect Warcraft's saved data to |cff40bbffC:\Users\|cffff8000USER|cff40bbff\AppData\Local\VirtualStore\Program Files\World of Warcraft|r, or possibly |cff40bbffC:\Users\Public\Games\World of Warcraft|r.

In that directory, the needed file is in |cff40bbffWTF/Account/|cffff8000ACCOUNT|cff40bbff/SavedVariables|r, replacing ACCOUNT with the name of your account, and in that directory, you should find |cff40bbffQuestHelper.lua|r.

There are other directories with the names of the realms where your characters are stored, |cffffff00but don't enter them|r. They contain information specific to your characters, such as the flight points they know about, and don't contain the quest information I want.

After you find |cff40bbffQuestHelper.lua|r, you can email it to me here: |cff40bbffqhaddon@gmail.com|r
]], "How To Submit Your Data")
end

function QuestHelper:ShowError()
  QuestHelper_ErrorCatcher_ReportError()
end

local commands

function QuestHelper:Help(argument)
  local text = ""
  local argument = argument and argument:upper() or ""
  
  for i1, cat in ipairs(commands) do
    text = string.format("%s|cffffff00%s|r\n\n", text, cat[1])
    for i, data in ipairs(cat[2]) do
      if data[1]:find(argument, 1, true) then
        text = string.format("%s    |cffff8000%s|r   %s\n", text, data[1], data[2])
        
        if #data[3] > 0 then
          text = string.format("%s\n      %s\n", text, #data[3] == 1 and "Example:" or "Examples:")
          for i, pair in ipairs(data[3]) do
            text = string.format("%s        |cff40bbff%s|r\n          %s\n", text, pair[1], pair[2])
          end
        end
        
        text = text .. "\n"
      end
    end
    text = text .. "\n\n"
  end
  
  self:ShowText(text == "" and ("No commands containing '"..argument.."'") or text, "QuestHelper Slash Commands")
end

function QuestHelper:Donate(argument)
  local text = ""
  local argument = argument and argument:upper() or ""
  
  for i1, cat in ipairs(commands) do
    text = string.format("%s|cffffff00%s|r\n\n", text, cat[1])
    for i, data in ipairs(cat[2]) do
      if data[1]:find(argument, 1, true) then
        text = string.format("%s    |cffff8000%s|r   %s\n", text, data[1], data[2])
        
        if #data[3] > 0 then
          text = string.format("%s\n      %s\n", text, #data[3] == 1 and "Example:" or "Examples:")
          for i, pair in ipairs(data[3]) do
            text = string.format("%s        |cff40bbff%s|r\n          %s\n", text, pair[1], pair[2])
          end
        end
        
        text = text .. "\n"
      end
    end
    text = text .. "\n\n"
  end
  
  self:ShowText([[
QuestHelper currently survives on |cffff8000your donations|r. I'm trying to make this into a full-time job so I can add more features and fix bugs, and I can't do that without paying the bills.

There's a lot of stuff I plan to add if I can get enough donations to live off. Some of the most-requested features include:

  |cff40bbffReduced memory and CPU usage for smoother gameplay|r
  
  |cff40bbffFlying mount support for both Northrend and Outland|r
  
  |cff40bbffBetter support for Northrend "phased" quests|r
  
  |cff40bbffAchievementHelper, built right into QuestHelper|r
  
  |cff40bbffPaths that lead you around obstacles instead of through them|r

I can't guarantee these will show up soon, as there's a lot of work involved in them, but every donation - no matter how small - helps!

To donate, open up your web browser and go to |cffff8000http://www.quest-helper.com/donate|r. Enter however much you feel comfortable donating, then bask in the knowledge that you're supporting QuestHelper.

Thanks!]], "Please Donate!", 500, 20, 10)
end

commands =
 {
  { "Common commands", {
    {"HIDDEN",
     "Compiles a list of objectives that QuestHelper is hiding from you. Depending on the reason, you can also unhide the objective.",
     {}, QuestHelper.ShowHidden, QuestHelper},
    
    {"HIDE",
     "Hides QuestHelper's modifications to the minimap and world map, and pauses routing calculations.",
      {}, QuestHelper.ToggleHide, QuestHelper},
      
    {"CARTWP",
     "Toggles displaying the current objective using Cartographer Waypoints (must be installed separately).",
      {}, QuestHelper.ToggleCartWP, QuestHelper},
    
    {"TOMTOM",
     "Toggles displaying the current objective using TomTom (must be installed separately).",
      {}, QuestHelper.ToggleTomTomWP, QuestHelper},
      
    {"FIND",
     "Search for an item, location, or npc.",
     {{"/qh find item rune of teleport", "Finds a reagent vendor."},
      {"/qh find npc bragok", "Finds the Ratchet flight point."},
      {"/qh find loc stormwind 50 60", "Finds the Stormwind auction house."},
      {"/qh find loc 50 50", "Finds the center of the zone you're in."},
      {"/qh find something", "Searches for something in all categories."},
      {"/qh find", "Lists objectives you manually created so that you can remove them."}}, QuestHelper.PerformSearch, QuestHelper},
    
    {"SOLO",
     "Toggles solo mode. When enabled, assumes your party members don't exist. Objective sharing with party members will also be disabled.",
      {}, QuestHelper.ToggleSolo, QuestHelper},
  }},

  { "Objective filtering", {
    {"FILTER",
     "Automatically ignores/unignores objectives based on criteria.",
     {{"/qh filter zone", "Toggle showing objectives outside the current zone"},
      {"/qh filter done", "Toggle showing objectives for uncompleted quests."},
      {"/qh filter level", "Toggle showing objectives that are probably too hard, by considering the levels of you and your party members, and the offset set by the level command."},
      {"/qh filter blocked", "Toggle showing blocked objectives, such as quest turn-ins for incomplete quests."},
      {"/qh filter watched", "Toggle limiting to objectives watched in the Quest Log"}
      }, QuestHelper.Filter, QuestHelper},
    
    {"LEVEL",
     "Adjusts the level offset used by the level filter. Naturally, the level filter must be turned on to have an effect.",
     {{"/qh level", "See information related to the level filter."},
      {"/qh level 0", "Only allow objectives at or below your current level."},
      {"/qh level +2", "Allow objectives up to two levels above your current level."},
      {"/qh level -1", "Only allow objectives below your current level."}}, QuestHelper.LevelOffset, QuestHelper},
    
    {"SCALE",
     "Scales the map icons used by QuestHelper. Will accept values between 50% and 300%.",
     {{"/qh scale 1", "Uses the default icon size."},
      {"/qh scale 2", "Makes icons twice their default size."},
      {"/qh scale 80%", "Makes icons slightly smaller than their default size."}},
      QuestHelper.genericSetScale, QuestHelper, "scale", "icon scale", .5, 3},
    
    {"SHARE",
     "Toggles objective sharing between QuestHelper users.",
      {}, QuestHelper.ToggleShare, QuestHelper},
  }},
  
  { "Interface", {
    {"TRACK",
     "Toggles the visibility of the QuestHelper's replacement quest tracker.",
      {}, QuestHelper.ToggleTrack, QuestHelper},
    
    {"TSCALE",
     "Scales the quest tracker provided by QuestHelper. Will accept values between 50% and 300%.",
     {},
     QuestHelper.TrackerScale, QuestHelper},
    
    {"TLEVEL",
     "Toggles display of levels in the quest tracker provided by QuestHelper.",
     {}, QuestHelper.ToggleTrackLevel, QuestHelper},
    
    {"TQCOL",
     "Toggles display of colours for the difficulty level of quests in the quest tracker provided by QuestHelper.",
     {}, QuestHelper.ToggleTrackQColour, QuestHelper},
    
    {"TOCOL",
     "Toggles display of colours for objective progress in the quest tracker provided by QuestHelper.",
     {}, QuestHelper.ToggleTrackOColour, QuestHelper},
    
    {"TRESET",
     "Reset's the position of the quest tracker provided by QuestHelper, in cause you move it somewhere inaccessable.",
     {{"/qh treset center", "Resets to the center of the screen, instead of a more normal quest tracker location."}}, QuestHelper.ResetTrackerPosition, QuestHelper},
     
    {"TOOLTIP",
     "Toggles appending information about tracked items and NPCs to their tooltips.",
      {}, QuestHelper.ToggleTooltip, QuestHelper},
      
    {"FTIME",
     "Toggles display of flight time estimates.", {}, QuestHelper.ToggleFlightTimes, QuestHelper},
    
    {"ANTS",
     "Toggles the display of trails on the world map on and off.",
      {}, QuestHelper.ToggleAnts, QuestHelper},
    
    {"LOCALE",
     "Select the locale to use for displayed messages.",
      {}, QuestHelper.SetLocale, QuestHelper},
      
    {"BUTTON",
     "Toggles the display of QuestHelper's button on the world map.",
     {}, QuestHelper.ToggleMapButton, QuestHelper},

    {"SETTINGS",
     "Opens the Settings menu at the current cursor location. Note that not all settings can be changed through the menu.",
     {}, QuestHelper.DoSettingsMenu, QuestHelper},
  }},
  
  { "Data collection", {
    {"NAG",
     "Tells you if you have anything that's missing from the static database. It can only check quests from your own faction, as the quests of your opposing faction are ommitted to save memory.",
       {{"/qh nag verbose", "Prints the specific changes that were found."}}, QuestHelper.Nag, QuestHelper},
    
    {"PURGE",
     "Deletes all QuestHelper's collected data.", {}, QuestHelper.Purge, QuestHelper},
    
    {"HARDRESET",
     "Deletes all QuestHelper's collected data and resets QuestHelper preferences.", {}, QuestHelper.HardReset, QuestHelper},
  }},

  { "Performance and debug", {
    {"PERF",
     "Sets or shows the route workload. Higher means more agressive route updating, lower means better performance Accepts numbers between 10% and 500%.",
     {{"/qh perf", "Show current Performance Factor"},
      {"/qh perf 1", "Sets standard performance"},
      {"/qh perf 50%", "Does half as much background processing"},
      {"/qh perf 3", "Computes routes 3 times more aggressively.  Better have some good horsepower!"}},
      QuestHelper.genericSetScale, QuestHelper, "perf_scale", "performance factor", .01, 5},
    
    {"PERFLOAD",
       "Sets or shows the initialization workload. Higher numbers will make QuestHelper load faster, lower numbers will result in better framerate while it's loading.",
       {{"/qh perfload", "Show current Performance Factor"},
        {"/qh perfload 1", "Sets standard performance"},
        {"/qh perfload 50%", "Does half as much background processing"},
        {"/qh perfload 3", "Loads 3 times as quickly."}},
        QuestHelper.genericSetScale, QuestHelper, "perfload_scale", "boot performance factor", .2, 5},
        
    {"TOP",
     "Displays various performance stats on QuestHelper.",
      {
        {"/qh top recycle", "Displays detailed information on QuestHelper's recycled item pools"},
        {"/qh top usage", "Displays detailed information on which table types are most common"},
        {"/qh top cache", "Displays detailed information on the internal distance cache"},
        {"/qh top perf", "Displays detailed information on coroutine CPU usage"},
      }, QuestHelper.Top, QuestHelper},
    
    {"ERROR",
     "Displays the first QuestHelper error that has been generated this session in a form which can be copied out of WoW.",
     {}, QuestHelper.ShowError, QuestHelper},
     
    {"POS",
      "Prints the player's current position. Exists mainly for my own personal convenience.",
      {}, function (qh) qh:TextOut(qh:LocationString(qh.i, qh.x, qh.y) .. "   " .. qh:LocationStringRaw(qh:RetrieveRawLocation())) end, QuestHelper},
      
    {"COMM",
     "Toggles showing of the communication between QuestHelper users. Exists mainly for my own personal convenience.",
      {}, QuestHelper.ToggleComm, QuestHelper},
      
    {"RECALC",
     "Recalculates the world graph and locations for any active objectives. Should not be necessary.", {}, QuestHelper.WantPathingReset, QuestHelper},
  }},
  
  { "Help", {
    {"HELP",
     "Displays a list of help commands. Listed commands are filtered by the passed string.",
     {}, QuestHelper.Help, QuestHelper},
     
    {"VERSION",
     "Displays QuestHelper's version.", {}, QuestHelper.PrintVersion, QuestHelper},
    
    {"CHANGES",
     "Displays a summary of changes recently made to QuestHelper.",
     {}, QuestHelper.ChangeLog, QuestHelper},
    
    {"DONATE",
     "Displays some instructions and a link for donating.",
     {}, QuestHelper.Donate, QuestHelper},
  }},
}

function QuestHelper_SlashCommand(input)
  local _, _, command, argument = string.find(input, "^%s*([^%s]-)%s+(.-)%s*$")
  if not command then
    command, argument = input, ""
  end
  
  command = string.upper(command)
  
  for i1, cat in ipairs(commands) do
    for i, data in ipairs(cat[2]) do
      if data[1] == command then
        local st = {}
        
        for i = 5,#data do table.insert(st, data[i]) end
        table.insert(st, argument)
        
        if type(data[4]) == "function" then
          data[4](unpack(st))
        else
          QuestHelper:TextOut(data[1].." is not yet implemented.")
        end
        
        return
      end
    end
  end
  
  QuestHelper:Help()
end

SLASH_QuestHelper1 = "/qh"
SLASH_QuestHelper2 = "/questhelper"
SlashCmdList["QuestHelper"] = function (text) QuestHelper_SlashCommand(text) end
