# ShowMMR v2 вЂ” Dota 2 MMR Dashboard Mod

by [t.me/xanoya](https://t.me/xanoya) | 2026-08-30

![Preview](preview.png)


Модификация для отображения MMR в истории матчей Dota 2. После установки в профиле появляется колонка **Result** с рейтингом (например, `5432 (+25)`).

## 🚀 Установка
1. **Запустите установщик от имени администратора:**
   - `ShowMMR_ru.bat` — русская версия
   - `ShowMMR_en.bat` или `dasasd.bat` — английская версия
   
   > **Важно:** ПКМ → *Запуск от имени администратора*

2. **В меню выберите:** `1 Установить`
   
   Мод скопируется в:

Steam\steamapps\common\dota 2 beta\game\dota_mods\pak02_dir.vpk

text

3. **Уберите `-nojoy` из параметров запуска Dota 2**

Мод использует слоты `JOY1-JOY32` для хранения истории матчей.

4. **Перезапустите Dota 2**

Профиль → История матчей → колонка **Result** с MMR.

## РЎР±РѕСЂРєР°

| РљРѕРјР°РЅРґР° | РћРїРёСЃР°РЅРёРµ |
|---|---|
| `6` РЎРѕР±СЂР°С‚СЊ VPK | РљРѕРјРїРёР»РёСЂСѓРµС‚ `source\` РІ `pak02_dir.vpk` С‡РµСЂРµР· `build_vpk.bat` (С‚СЂРµР±СѓРµС‚СЃСЏ `resourcecompiler`). Р•СЃР»Рё РѕС‚СЃСѓС‚СЃС‚РІСѓРµС‚ вЂ” РёСЃРїРѕР»СЊР·СѓРµС‚СЃСЏ РіРѕС‚РѕРІС‹Р№ `pak02_dir.vpk` (30429) |
| `5` РћР±РЅРѕРІРёС‚СЊ MMR | Р—Р°РїСѓСЃРєР°РµС‚ `ShowMMR_tool\bin\Release\net48\ShowMMR.exe`. РљРµС€ `*.auth` СЂСЏРґРѕРј СЃ РёРЅСЃС‚СЂСѓРјРµРЅС‚РѕРј, `user_keys\` СЃРѕР·РґР°С‘С‚СЃСЏ Р°РІС‚РѕРјР°С‚РёС‡РµСЃРєРё |

## РЎС‚СЂСѓРєС‚СѓСЂР° РїСЂРѕРµРєС‚Р°

```
source\              # РёСЃС…РѕРґРЅРёРєРё РїР°РЅРѕСЂР°РјС‹/lua (13 С„Р°Р№Р»РѕРІ)
ShowMMR_tool\        # C# SteamKit2 С‚СѓР»Р·Р° (Program.cs, *.csproj) + bin\Release\net48\ShowMMR.exe
ShowMMR_en.bat       # EN РёРЅСЃС‚Р°Р»Р»СЏС‚РѕСЂ (UTF-8)
ShowMMR_ru.bat       # RU РёРЅСЃС‚Р°Р»Р»СЏС‚РѕСЂ (CP866)
dasasd.bat           # РіР»Р°РІРЅС‹Р№ EN (РєРѕРїРёСЏ ShowMMR_en.bat)
pak02_dir.vpk        # СЃРѕР±СЂР°РЅРЅС‹Р№ РјРѕРґ (30429, РёР· РЁСЂРµРє12)
user_keys\           # СЃСЋРґР° РіРµРЅРµСЂРёСЂСѓРµС‚СЃСЏ user_keys_<steamid>_slot3.vcfg
preview.png          # СЃРєСЂРёРЅС€РѕС‚
```

### РџСѓС‚СЊ РґР°РЅРЅС‹С…

```
                         _______________________
                         | scripts /            |  3  | GetTableValue |
                         | custom_net_tables.txt|_____|_______________|
                         |  __>___>___>__       |     |  panorama /    |
                         |^|             |      |     |  scripts /     |
                   ______| |_____        |      |     |  showmmr/      |
   C# ShowMMR_tool |             2|      |      |     |  data.js       |
   SteamKit2 GC -> | scripts /    |______|______|_____|  logic.js      | 4
   user_keys_%d_   | vscripts /   |      SendCustomGameEvent            | panorama / layout /
   slot3.vcfg  1   | core /       |_____________________________________| base.xml
    _______________| coreinit.lua |      |     DOTARankUpdated          | dashboard_page_
   |               |______________|      |     DOTAShowLocalProfile..   | profile_hero_stats.xml
   |  LoadKeyValues |     |              |     #ranked_mmr_value        |_______________|
   |_______________>|_____|___________   |_______________    |__________|      | 5
                          |           6  | panorama /     |  |  core.Data.history
                          |  panorama /  | images /       |__|__________________|
                          |  layout /    | background.png |
                          |______________|________________|
```

`1` `cfg/user_keys_%d_slot3.vcfg` в†’ `LoadKeyValues` в†’ `2 coreinit.lua` в†’ `SetTableValue` в†’ `3 custom_net_tables.txt` в†’ `4 panorama/layout` в†’ `5 dashboard` + `6 panorama/images`

## Р”РёР°РіРЅРѕСЃС‚РёРєР°

РњРµРЅСЋ в†’ `8` Р”РёР°РіРЅРѕСЃС‚РёРєР° РїСЂРѕРІРµСЂСЏРµС‚:

- `SteamPath` (СЂРµРµСЃС‚СЂ `HKCU\Software\Valve\Steam`)
- `DOTA_PATH`
- РќР°Р»РёС‡РёРµ `dota_mods`
- РџСЂР°РІР° Р°РґРјРёРЅРёСЃС‚СЂР°С‚РѕСЂР°
- РЎРІРѕР±РѕРґРЅРѕРµ РјРµСЃС‚Рѕ

Р›РѕРі: `showmmr_log.txt` (СЂРѕС‚Р°С†РёСЏ 10 РњР‘).

## РўСЂРµР±РѕРІР°РЅРёСЏ

- РћРЎ: Windows 10/11
- РџР»Р°С‚С„РѕСЂРјР°: Steam + Dota 2
- РџСЂР°РІР°: РђРґРјРёРЅРёСЃС‚СЂР°С‚РѕСЂ (РґР»СЏ СѓСЃС‚Р°РЅРѕРІРєРё)

> вљ пёЏ РСЃРїРѕР»СЊР·СѓР№С‚Рµ РЅР° СЃРІРѕР№ СЃС‚СЂР°С… Рё СЂРёСЃРє вЂ” Valve РёСЃС‚РѕСЂРёС‡РµСЃРєРё РЅРµ Р±Р°РЅРёР»Р° Р·Р° РґР°С€Р±РѕСЂРґ-РјРѕРґС‹.

## РљРѕРЅС‚Р°РєС‚С‹

Telegram: [@xanoya](https://t.me/xanoya) вЂ” 2026-08-30
