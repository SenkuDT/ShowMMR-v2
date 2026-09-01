ShowMMR v2 — MMR в профиле Dota 2

by t.me/xanoya | 2026-08-30

Preview

Модификация для отображения MMR в истории матчей Dota 2. После установки в профиле появляется колонка Result с рейтингом (например, 5432 (+25)).
🚀 Установка

    Запустите установщик от имени администратора:

        ShowMMR_ru.bat — русская версия

        ShowMMR_en.bat или dasasd.bat — английская версия

    В меню выберите 1 Установить — мод скопируется в:

    text
    Steam\steamapps\common\dota 2 beta\game\dota_mods\pak02_dir.vpk

    Уберите -nojoy из параметров запуска Dota 2 (мод хранит историю в JOY1-JOY32)

    Перезапустите Dota 2 → Профиль → История матчей → колонка Result с MMR

🛠 Сборка
Команда	Описание
6 Собрать VPK	Компилирует source\ в pak02_dir.vpk через build_vpk.bat (требуется resourcecompiler). Если отсутствует — используется готовый pak02_dir.vpk (сборка 30429)
5 Обновить MMR	Запускает ShowMMR_tool\bin\Release\net48\ShowMMR.exe. Кеш *.auth рядом с инструментом, user_keys\ создаётся автоматически
📁 Структура проекта

text
source\              # исходники панорамы/lua (13 файлов)
ShowMMR_tool\        # C# SteamKit2 тулза (Program.cs, *.csproj) + bin\Release\net48\ShowMMR.exe
ShowMMR_en.bat        # EN инсталлятор (UTF-8)
ShowMMR_ru.bat        # RU инсталлятор (CP866)
dasasd.bat            # главный EN (копия ShowMMR_en.bat)
pak02_dir.vpk         # собранный мод (30429, из Шрек12)
user_keys\           # сюда генерируется user_keys_<steamid>_slot3.vcfg
preview.png           # скриншот

🏗 Архитектура

text
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

Поток данных:

cfg/user_keys_%d_slot3.vcfg → LoadKeyValues → coreinit.lua → SetTableValue → custom_net_tables.txt → panorama/layout → dashboard + panorama/images
🔍 Диагностика

Меню → 8 Диагностика проверяет:

    SteamPath (реестр HKCU\Software\Valve\Steam)

    DOTA_PATH

    Наличие dota_mods

    Права администратора

    Свободное место

Лог: showmmr_log.txt (ротация 10 МБ).
⚙️ Требования

    ОС: Windows 10/11

    Платформа: Steam + Dota 2

    Права: Администратор (для установки)

⚠️ Отказ от ответственности

    Используйте на свой страх и риск — Valve исторически не банила за дашборд-моды.

📬 Контакты

Telegram: @xanoya | 2026-08-30
