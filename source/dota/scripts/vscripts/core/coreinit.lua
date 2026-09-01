-- ShowMMR Bootstrap - clean implementation, loads new service
if not IsServer() then return end
print("[ShowMMR] bootstrap coreinit loading")
require('showmmr.service')
print("[ShowMMR] bootstrap done, service required")
