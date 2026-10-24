CHRONICLES OF ELDORIA
=====================

A 2D Pinoy folklore action adventure made in Godot 4.

HOW TO OPEN IT
  1. Install Godot 4.4 or newer (godotengine.org). The normal version is fine.
  2. Open Godot > Import > pick the project.godot file in this folder.
  3. Press F5 (Play). It starts on the main menu.

CONTROLS
  Move:    WASD or Arrow keys
  Attack:  Space, J, Z or left mouse button
  Pause:   Esc or P
  Mute:    M

HOW TO PLAY
  Defeat every monster in the world. The red portal turns green. Walk into it.
  Bawang (garlic) heals 2 hearts. Saging (banana) heals 1. Asin (salt) gives +1 damage.
  World 1: Barrio Eldoria (Aswang).  World 2: The Cursed Night (Aswang, Tikbalang, and the Manananggal boss).

WHERE THINGS ARE
  world.tscn / world_2.tscn   the two worlds
  Scripts/levels_data.gd      the maps! Each letter is one tile - edit them freely
  Scenes/aswang.tscn etc.     click a monster scene and change HP / speed in the Inspector
  Scripts/audio.gd            all sound effects and music (made in code)
  Audio/                      drop your own sounds here to replace them (see Audio/README.txt)
  Assets/                     all the pixel art (PNG)
  docs/                       your original game concept document

TO MAKE A .EXE
  Project > Export > Windows Desktop > Export Project (needs Godot's export templates).
