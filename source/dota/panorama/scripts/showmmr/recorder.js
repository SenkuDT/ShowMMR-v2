'use strict';
var ShowMMRRecorder = (function() {
  let _pending = false;
  function onRankUpdate() {
    if (_pending) return;
    _pending = true;
    $.Msg("[ShowMMR] recorder: rank update detected, scheduling save");
    $.Schedule(2.0, trySave);
  }
  let _retries = 0;
  function trySave() {
    _pending = false;
    if (_retries > 3) { $.Msg("[ShowMMR] recorder: max retries, stop"); _retries = 0; return; }
    let mmrVal = 0;
    let raw = "";
    try {
      let core2 = $('#Dashboard') ? $('#Dashboard').FindChildInLayoutFile('DashboardCore') : null;
      if (core2 && core2.Data.ShowMMR && core2.Data.ShowMMR.mmr > 0) {
        mmrVal = core2.Data.ShowMMR.mmr;
        raw = "core.Data.mmr=" + mmrVal;
      } else {
        let ctx = $('#Dashboard') || $.GetContextPanel();
        raw = $.Localize('#ranked_mmr_value', ctx);
        mmrVal = parseInt(raw.replace(/\D+/g, '')) || 0;
        if (!mmrVal) {
          let mmrLbl = $('#MMRNumber') || $('#TopBarMMR') || $('.MMRValue');
          if (mmrLbl) {
            let txt = mmrLbl.text || "";
            if (!txt && mmrLbl.GetChildCount && mmrLbl.GetChildCount()>0) txt = mmrLbl.GetChild(0).text;
            mmrVal = parseInt(txt.replace(/\D+/g, '')) || 0;
            raw = "label text='"+txt+"'";
          }
        }
        if (!mmrVal) {
          let topMmr = $('#TopBarRankedMMR') || $('#MMRContainer') || $.GetContextPanel().FindChildTraverse('MMRNumber');
          if (topMmr) {
            let t2 = topMmr.text || "";
            mmrVal = parseInt(t2.replace(/\D+/g, '')) || 0;
            raw = "topbar raw='"+t2+"'";
          }
        }
      }
      $.Msg("[ShowMMR] recorder: raw='"+raw+"' parsed="+mmrVal);
    } catch(e) { $.Msg("[ShowMMR] recorder: failed to read mmr " + e); }
    if (!mmrVal) { _retries++; $.Msg("[ShowMMR] recorder: mmr not ready, retry "+_retries+"/3"); $.Schedule(5.0, trySave); return; }
    _retries = 0;
    $.Msg("[ShowMMR] recorder: got mmr " + mmrVal + ", requesting save");
    GameEvents.SendCustomGameEventToServer("showmmr_record", { mmr: mmrVal });
  }
  function init() {
    $.RegisterForUnhandledEvent('DOTARankUpdated', onRankUpdate);
    $.RegisterForUnhandledEvent('DOTAGameAccountClientUpdated', onRankUpdate);
    $.Msg("[ShowMMR] recorder init");
  }
  $.Schedule(1.0, init);
  return { onRankUpdate };
})();
