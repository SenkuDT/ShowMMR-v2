-- ShowMMR Recorder - auto save for new games, clean implementation
if not IsServer() then return end
if ShowMMRRecorder == nil then ShowMMRRecorder = class({}) end

function ShowMMRRecorder:Init()
  if GameRules then return end
  self.pending = {}
  CustomGameEventManager:RegisterListener("showmmr_record", function(_, e) return self:OnRecord(e) end)
  Convars:RegisterCommand('showmmr_fetch', function(_, k, v) 
    if k and v and k:match('^recent_game_time_%d$') then self.pending[k] = v end
    if k == 'showmmr_do_save' and v == '1' then self:DoSave() end
  end, 'internal', 0)
  print("[ShowMMR] recorder init")
end

function ShowMMRRecorder:OnRecord(e)
  self.newMMR = tonumber(e.mmr) or 0
  print("[ShowMMR] recorder OnRecord mmr=" .. tostring(self.newMMR))
  if self.newMMR <= 0 then return end
  self:DoSave()
end

function ShowMMRRecorder:DoSave()
  local t1 = math.floor(Time())
  if not t1 or self.newMMR <= 0 then print("[ShowMMR] recorder DoSave no data"); return end
  local history = {}
  local kv = LoadKeyValues('cfg/user_keys_' .. (self.user or "0") .. '_slot3.vcfg')
  if kv and kv.matches then
    for _, v in pairs(kv.matches) do history[tonumber(v.date)] = {tonumber(v.mmr), tonumber(v.outcome)} end
  end
  local prevMMR = 0
  local lastDate = 0
  for k,v in pairs(history) do if k > lastDate then lastDate = k; prevMMR = v[1] end end
  local delta = 0
  if prevMMR > 0 then
    delta = self.newMMR - prevMMR
    if math.abs(delta) > 500 then delta = 0 end
  end
  if history[t1] and history[t1][1] ~= 0 then
    print("[ShowMMR] recorder already has mmr for " .. t1)
    return
  end
  history[t1] = {self.newMMR, delta}
  print("[ShowMMR] recorder save " .. t1 .. " mmr " .. self.newMMR .. " delta " .. delta)
  CustomNetTables:SetTableValue('ShowMMR_History', ' ' .. t1, {self.newMMR, delta})
  CustomNetTables:SetTableValue('ShowMMR_Update', ' ' .. t1, {self.newMMR, delta})
end

ListenToGameEvent('player_connect', function(e) 
  if not ShowMMRRecorder.user then
    ShowMMRRecorder.user = e.networkid:match('^%[%a:[0-5]:(%d+).*%]$') or "0"
    ShowMMRRecorder:Init()
  end
end, nil)
