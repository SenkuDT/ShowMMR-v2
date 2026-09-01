-- bridge_test.lua - verifies bridge contract
require('showmmr.bridge')
local Bridge = require('showmmr.bridge')

local function assert(cond, msg) if not cond then error("bridge_test failed: " .. (msg or "")) end end

local data, err = Bridge:Request("current_mmr")
-- Test 1: data exists or proper error
if data == nil then
  assert(err == "data_unavailable" or err == "unsupported_version" or err == "missing_account_id", "wrong error for missing data: " .. tostring(err))
  print("[showmmr] bridge_test: current_mmr unavailable as expected: " .. err)
else
  assert(type(data.mmr) == "number", "mmr should be number")
  print("[showmmr] bridge_test: current_mmr=" .. tostring(data.mmr))
end

local matches, err2 = Bridge:Request("ranked_matches")
if matches == nil then
  print("[showMMR] bridge_test: ranked_matches unavailable: " .. tostring(err2))
else
  assert(type(matches) == "table", "matches should be table")
  for _, m in ipairs(matches.matches or matches) do
    assert(m.match_id ~= nil, "match missing match_id")
  end
  print("[showMMR] bridge_test: matches count=" .. tostring(#(matches.matches or matches)))
end

-- Test ready flag
local ready = Bridge:IsReady()
print("[showMMR] bridge_test: IsReady=" .. tostring(ready))

-- Test idempotency
local data2 = Bridge:Request("current_mmr")
assert((data == nil and data2 == nil) or (data and data2 and data.mmr == data2.mmr), "idempotency failed")

print("[showMMR] bridge_test: PASSED")
