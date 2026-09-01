'use strict';
var ShowMMRLogic = (function() {
  function current() {
    let best = null; let bestDate = 0;
    for (let [date, rec] of ShowMMRData.entries()) {
      if (rec.mmr > 0 && date > bestDate) { bestDate = date; best = rec; }
    }
    return best;
  }
  function stats() {
    let wins = 0, losses = 0, uncal = 0;
    for (let [, rec] of ShowMMRData.entries()) {
      if (rec.mmr === 0 && rec.delta === 0) uncal++;
      else if (rec.delta > 0) wins++;
      else if (rec.delta < 0) losses++;
    }
    return { wins, losses, uncal, total: ShowMMRData.size() };
  }
  return { current, stats };
})();
