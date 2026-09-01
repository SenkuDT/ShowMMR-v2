-- bridge.lua - adapter reading published data, not GC client
local Bridge = {}
Bridge.VERSION = 1
Bridge.NETTABLE = "showmmr_data"

function Bridge:IsReady()
  local data = CustomNetTables:GetTableValue(Bridge.NETTABLE, "state")
  return data ~= nil and tonumber(data.ready) == 1
end

function Bridge:Request(request_type)
  local data = CustomNetTables:GetTableValue(Bridge.NETTABLE, request_type)
  if data == nil then
    return nil, "data_unavailable"
  end
  if tonumber(data.version) ~= Bridge.VERSION then
    return nil, "unsupported_version"
  end
  if data.account_id == nil or data.account_id == "" then
    return nil, "missing_account_id"
  end
  return data, nil
end

return Bridge
