# Advanced Camera for Source Engine Games
The aim of this plugin is to replicate the thirdperson_maya command from TF2 with SourceMod.

# Functionality
- Allows for a client to spawn a single camera via menu (for now).
-	Clients can control the position of the camera relative to their position in the world.
-	Clients can control the angle of the camera relative to their view angles in the world.
-	Clients can control if the camera should track them. (not tested).

# Requirements
- Sourcemod Version 1.9 or greater.
- Source Engine Game that can spawn the "point_viewcontrol" entity.

# Commands
- "sm_ac_menu" | Opens the Advanced Camera Menu to setup a camera.
- "sm_ac_spawn" | Allows for quick toggling of the camera.
- "sm_ac_pos" | Allows for quick re-setup of the camera pos setting.
- "sm_ac_ang" | Allows for quick re-setup of the camera ang setting.
- "sm_ac_track" | Allows for quick re-setup of camera track setting.