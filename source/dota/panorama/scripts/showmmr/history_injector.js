'use strict';
var ShowMMRHistoryInjector = (function() {
  let _paginate = -1;
  function inject() {
    let table = $('#RecentGamesTable');
    if (!table) return;
    _paginate++; if (_paginate > 19) _paginate = 0;
    let count = table.GetChildCount();
    if (count < 3 || count < _paginate) return;
    let rowPanel = table.GetChild(count - Math.min(count, 22) + _paginate);
    if (!rowPanel) return;
    let resultCol = rowPanel.FindChildrenWithClassTraverse('ResultColumn');
    let dateCol = rowPanel.FindChildrenWithClassTraverse('TimestampDate');
    let timeCol = rowPanel.FindChildrenWithClassTraverse('TimestampTime');
    let durCol = rowPanel.FindChildrenWithClassTraverse('DurationColumn');
    let typeCol = rowPanel.FindChildrenWithClassTraverse('GameTypeColumn');
    let result = resultCol ? resultCol[0] : null;
    let dateLbl = dateCol ? dateCol[0] : null;
    let timeLbl = timeCol ? timeCol[0] : null;
    let durLbl = durCol ? durCol[0] : null;
    let typeLbl = typeCol ? typeCol[0] : null;
    if (!result || !dateLbl || !timeLbl || !durLbl || !typeLbl) return;
    let typeText = typeLbl.text || "";
    if (typeText.indexOf('Рейтинг') === -1 && typeText.indexOf('Ranked') === -1 && typeText.indexOf('Competitive') === -1) return;
    let stampDate = dateLbl.text;
    let gmt = $.Localize('{T:d:timestamp}', rowPanel);
    let dst = $.Localize('{T:timestamp}', rowPanel);
    let utc = [];
    let hms = (gmt.match(/\d+/g) || []), ymd = (stampDate.match(/\d+/g) || []);
    let hour = hms.length>0?parseInt(hms[0]):0, minute = hms.length>1?parseInt(hms[1]):0, second = hms.length>2?parseInt(hms[2]):0;
    if (hms.length < 3) { second = minute; minute = hour; hour = 0; }
    let year = ymd.length>0?parseInt(ymd[0]):0, month = ymd.length>1?parseInt(ymd[1]):0, day = ymd.length>2?parseInt(ymd[2]):0;
    if (year < 32) { let f=day; day=year; year=f; }
    utc[0]=Date.UTC(year, month-1, day, hour, minute, second)/1000;
    utc[1]=Date.UTC(year, day-1, month, hour, minute, second)/1000;
    utc[2]=utc[0]-86400; utc[3]=utc[0]+86400; utc[4]=utc[1]-86400; utc[5]=utc[1]+86400;
    for(let i=0;i<6;i++) rowPanel.SetDialogVariableTime('utc'+i, utc[i]);
    let loc = $.Localize('{T:utc0}|{T:utc1}|{T:utc2}|{T:utc3}|{T:utc4}|{T:utc5}', rowPanel).split('|');
    let epoch = 0; for(let i=0;i<6;i++) if(loc[i]==dst) epoch = utc[i];
    if (!epoch) return;
    let rec = ShowMMRData.get(epoch);
    function setPill(text, bg, txtColor) {
      result.text = "";
      result.style.backgroundColor = "#00000000";
      let pill = result.FindChildTraverse('ShowMMRPill');
      if (!pill) { pill = $.CreatePanel('Label', result, 'ShowMMRPill'); }
      pill.text = text;
      pill.style.backgroundColor = bg;
      pill.style.borderRadius = "7px";
      pill.style.padding = "1px 8px";
      pill.style.height = "18px";
      pill.style.textAlign = "center";
      pill.style.horizontalAlign = "center";
      pill.style.verticalAlign = "center";
      pill.style.color = txtColor || "#ffffff";
      pill.style.fontWeight = "bold";
      pill.style.fontSize = "13px";
    }
    if (!rec) { setPill("—", "#3a3a3a", "#ffffff"); return; }
    if (rec.mmr === 0 && rec.delta === 0) { let t = $.Localize('#dota_profile_recent_game_result_uncalibrated_ranked') || "—"; setPill(t, "#3a3a3a", "#ffffff"); return; }
    if (rowPanel.BHasClass('Abandoned')) { let ab = $.Localize('#dota_profile_recent_game_result_abandon') || "Покинута"; setPill(ab + " ("+rec.delta+")", "#FF8C00", "#ffffff"); return; }
    rowPanel.SetDialogVariableInt('showmmr', rec.mmr);
    let mmrStr = $.Localize('{i:showmmr}', rowPanel);
    let pillText = mmrStr + (rec.delta>0 ? " (+"+rec.delta+")" : " ("+rec.delta+")");
    setPill(pillText, rec.delta > 0 ? "#078747" : rec.delta < 0 ? "#870707" : "#3a3a3a", "#ffffff");
    if (rec.delta > 0) { result.RemoveClass('Loss'); result.AddClass('Win'); } else if (rec.delta < 0) { result.RemoveClass('Win'); result.AddClass('Loss'); }
  }
  let _manualLock = false;
  function manualUpdate() {
    if (_manualLock) return;
    _manualLock = true;
    ShowMMRData.reload();
    _paginate = -1;
    let table = $('#RecentGamesTable');
    if (!table) { _manualLock = false; return; }
    for (let i=0;i<20;i++) inject();
    $.Schedule(2.0, function(){ _manualLock = false; });
  }
  return { inject, manualUpdate };
})();
