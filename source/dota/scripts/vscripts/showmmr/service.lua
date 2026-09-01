-- ShowMMR Service - data layer, independent implementation
if not IsServer() then return end
if ShowMMRService == nil then ShowMMRService = class({}) end

function ShowMMRService:Init(e)
  if GameRules then return end
  self.user = e.networkid:match('^%[%a:[0-5]:(%d+).*%]$') or "0"
  self.history = {}
  local path = 'cfg/user_keys_' .. self.user .. '_slot3.vcfg'
  local kv = LoadKeyValues(path)
  print("[ShowMMR] service Init user=" .. tostring(self.user) .. " path=" .. path .. " kv=" .. tostring(kv ~= nil))
  if kv == nil then
    print("[ShowMMR] try fallback user_keys_0_slot3.vcfg")
    kv = LoadKeyValues('cfg/user_keys_0_slot3.vcfg')
  end
  local hasMatches = kv and kv.matches ~= nil
  print("[ShowMMR] hasMatches=" .. tostring(hasMatches) .. " bindings=" .. tostring(kv and kv.bindings ~= nil))
  if kv and kv.bindings then
    local c = 0; for _ in pairs(kv.bindings) do c=c+1 end; print("[ShowMMR] bindings count=" .. c)
  end
  if kv and kv.matches then
    local cnt = 0; for _ in pairs(kv.matches) do cnt=cnt+1 end; print("[ShowMMR] matches raw count=" .. cnt)
    for _, v in pairs(kv.matches) do
      if v.date and v.mmr ~= nil then
        local d = tonumber(v.date); local m = tonumber(v.mmr) or 0; local o = tonumber(v.outcome) or 0
        if d then self.history[d] = { m, o } end
      end
    end
    local hcnt=0; for _ in pairs(self.history) do hcnt=hcnt+1 end; print("[ShowMMR] history built size=" .. hcnt)
  else
    print("[ShowMMR] no matches block, history stays empty")
  end
  local out, count, chunk = {}, 0, 0
  local total=0; for _ in pairs(self.history) do total=total+1 end
  print("[ShowMMR] publishing history total=" .. total)
  for k, v in pairs(self.history) do
    out[' ' .. k] = { v[1], v[2] }
    count = count + 1
    if count >= 400 then
      CustomNetTables:SetTableValue('ShowMMR_History', tostring(chunk), out)
      print("[ShowMMR] chunk "..chunk.." size "..count)
      out = {}; count = 0; chunk = chunk + 1
    end
  end
  CustomNetTables:SetTableValue('ShowMMR_History', 'main', out)
  print("[ShowMMR] published main chunk size "..count.." chunks="..(chunk+1))
  if total==0 then print("[ShowMMR] WARNING history empty, check file path/format") end
  -- Publish for new bridge (showmmr_data)
  if CustomNetTables then
    local current_mmr = 0; local last_date = 0
    for k,v in pairs(self.history) do if k > last_date then last_date = k; current_mmr = v[1] end end
    CustomNetTables:SetTableValue('showmmr_data', 'state', {version=1, ready=1, account_id=tostring(self.user)})
    CustomNetTables:SetTableValue('showmmr_data', 'current_mmr', {version=1, account_id=tostring(self.user), mmr=current_mmr})
    local matches_arr = {}
    for k,v in pairs(self.history) do table.insert(matches_arr, {match_id=tostring(k), date=k, mmr=v[1], mmr_change=v[2]}) end
    table.sort(matches_arr, function(a,b) return a.date > b.date end)
    CustomNetTables:SetTableValue('showmmr_data', 'ranked_matches', {version=1, account_id=tostring(self.user), matches=matches_arr})
    print("[ShowMMR] bridge published showmmr_data ready=1 mmr="..current_mmr.." matches="..#matches_arr)
  else
    print("[ShowMMR] CustomNetTables not ready, skip bridge publish")
  end
end

function ShowMMRService:Reload(e)
  print("[ShowMMR] reload triggered")
  self:Init(e)
end
if CustomGameEventManager then
  CustomGameEventManager:RegisterListener("showmmr_reload", function(_, e) ShowMMRService:Reload(e) end)
end
if Convars then
  Convars:RegisterCommand('showmmr_bridge_test', function()
    print("[ShowMMR] running bridge_test")
    local ok, err = pcall(function() require('showmmr.bridge_test') end)
    if not ok then print("[ShowMMR] bridge_test failed: " .. tostring(err)) end
  end, 'test bridge', 0)
end
ListenToGameEvent('player_connect', Dynamic_Wrap(ShowMMRService, 'Init'), ShowMMRService)
