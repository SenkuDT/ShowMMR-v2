'use strict';
var ShowMMRData = (function() {
  let _map = new Map();
  let _loaded = false;
  function load() {
    if (_loaded) return;
    _loaded = true;
    let all = CustomNetTables.GetAllTableValues('ShowMMR_History');
    $.Msg("[ShowMMR] data.js load tables=" + all.length);
    for (let entry of all) {
      let kv = entry.value;
      if (!kv) continue;
      let keys = Object.keys(kv);
      $.Msg("[ShowMMR] chunk " + entry.key + " keys=" + keys.length + " sample=" + (keys[0]||"none"));
      for (let k in kv) {
        let v = kv[k];
        if (k === 'count') continue;
        let date = parseInt(k);
        if (!isNaN(date) && v) _map.set(date, { mmr: v['1'], delta: v['2'] });
      }
    }
    $.Msg("[ShowMMR] data.js loaded map size=" + _map.size);
    if (_map.size === 0) $.Msg("[ShowMMR] WARNING data empty, check service.lua path/format");
  }
  function reload() {
    $.Msg("[ShowMMR] data.js reload triggered");
    _map.clear(); _loaded = false; load();
    $.Msg("[ShowMMR] data.js reload done size=" + _map.size);
  }
  function get(date) { if (!_loaded) load(); return _map.get(date) || null; }
  function has(date) { if (!_loaded) load(); return _map.has(date); }
  function size() { if (!_loaded) load(); return _map.size; }
  function entries() { if (!_loaded) load(); return Array.from(_map.entries()); }
  CustomNetTables.SubscribeNetTableListener('ShowMMR_History', function(t,k,v){
    if (!v) return;
    $.Msg("[ShowMMR] History update chunk=" + k + " keys=" + Object.keys(v).length);
    for (let ik in v) {
      if (ik === 'count') continue;
      let d = parseInt(ik); if (!isNaN(d)) _map.set(d, {mmr: v[ik]['1'], delta: v[ik]['2']});
    }
  });
  CustomNetTables.SubscribeNetTableListener('ShowMMR_Update', function(t,k,v){
    if (!v) return;
    let d = parseInt(k); if (!isNaN(d)) { _map.set(d, {mmr: v['1'], delta: v['2']}); $.Msg("[ShowMMR] Update set date=" + d + " mmr=" + v['1']); }
  });
  return { get, has, size, entries, load, reload };
})();
