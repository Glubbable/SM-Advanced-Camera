#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION	"1.0.2"
#define PLUGIN_DESC	"Allows a client to setup to camera their world model."
#define PLUGIN_NAME	"[ANY] Advanced Camera"
#define PLUGIN_AUTH	"Glubbable"
#define PLUGIN_URL	"https://steamcommunity.com/groups/GlubsServers"

int g_iClientCameraRef[MAXPLAYERS + 1] = INVALID_ENT_REFERENCE;
bool g_bClientCameraTrack[MAXPLAYERS + 1] = false;
float g_flClientCameraPos[MAXPLAYERS + 1][3];
float g_flClientCameraAng[MAXPLAYERS + 1][3];
Menu g_mClientCurrentMenu[MAXPLAYERS + 1] = null;

public const Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTH,
	description = PLUGIN_DESC,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL,
};

public void OnPluginStart()
{
	RegAdminCmd("sm_ac_menu", Command_CameraMenu, ADMFLAG_GENERIC, "Opens Advanced Camera Menu.");
	
	RegAdminCmd("sm_ac_spawn", Command_CameraSpawn, ADMFLAG_GENERIC, "Quick Spawn/Removes Camera for Advanced Camera.");
	RegAdminCmd("sm_ac_pos", Command_CameraPos, ADMFLAG_GENERIC, "Quick Position Setup for Advanced Camera.");
	RegAdminCmd("sm_ac_ang", Command_CameraAng, ADMFLAG_GENERIC, "Quick Angle Setup for Advanced Camera.");
	RegAdminCmd("sm_ac_track", Command_CameraTrack, ADMFLAG_GENERIC, "Quick Track Setup for Advanced Camera.");
	
	for (int iClient = MaxClients; iClient > 0; iClient--)
		OnClientPutInServer(iClient); // Force set values on late load.
}

public void OnPluginEnd()
{
	for (int iClient = MaxClients; iClient > 0; iClient--)
	{
		if (!IsClientInGame(iClient))
			continue;
		
		OnClientDisconnect(iClient); // Force set values on late load.
	}
}

const AC_Client AC_INVALID_CLIENT = view_as<AC_Client>(0);
methodmap AC_Client __nullable__
{
	property int iIndex
	{
		public get()
		{
			return view_as<int>(this);
		}
	}
	property int iCamera
	{
		public get()
		{
			int iEntity = EntRefToEntIndex(g_iClientCameraRef[this.iIndex]);
			if (!IsValidEntity(iEntity)) // Failsafe.
				iEntity = INVALID_ENT_REFERENCE;
			
			return iEntity;
		}
		public set(int iEntity)
		{
			g_iClientCameraRef[this.iIndex] = EntIndexToEntRef(iEntity);
		}
	}
	property bool bCameraTrack
	{
		public get()
		{
			return g_bClientCameraTrack[this.iIndex];
		}
		public set(bool bState)
		{
			g_bClientCameraTrack[this.iIndex] = bState;
		}
	}
	property Menu mCurrentMenu
	{
		public get()
		{
			return g_mClientCurrentMenu[this.iIndex];
		}
		public set (Menu mMenu)
		{
			g_mClientCurrentMenu[this.iIndex] = mMenu;
		}
	}
	
	public AC_Client(int iClient)
	{
		if (iClient == 0)
			return view_as<AC_Client>(AC_INVALID_CLIENT);
		
		return view_as<AC_Client>(iClient);
	}
	public bool CheckClient()
	{
		int iClient = this.iIndex;
		if (iClient == 0)
		{
			PrintToChat(iClient, "[SM] This command is for clients only!");
			return false;
		}
		
		bool bInGame = IsClientInGame(iClient);
		if (!bInGame)
			return false;
		
		if (bInGame && !IsPlayerAlive(iClient))
		{
			PrintToChat(iClient, "[SM] You need to be alive to spawn a camera!");
			return false;
		}
		
		return true;
	}
	public void SendMessage(const char[] sMessage)
	{
		PrintToChat(this.iIndex, "%s", sMessage);
	}
	public void GetCameraPos(float vecBuffer[3])
	{
		for (int i = 0; i < 3; i++)
			vecBuffer[i] = g_flClientCameraPos[this.iIndex][i];
	}
	public void GetCameraAng(float vecBuffer[3])
	{
		for (int i = 0; i < 3; i++)
			vecBuffer[i] = g_flClientCameraAng[this.iIndex][i];
	}
	public void ToggleThirdPerson(bool bState)
	{
		SetEntProp(this.iIndex, Prop_Send, "m_nForceTauntCam", bState);
	}
	
	public void DisplayCameraMenu()
	{
		Menu mMenu = new Menu(Menu_Camera);
		mMenu.SetTitle("Advanced Camera Menu:");
		mMenu.ExitBackButton = false;
		
		bool bCamera = view_as<bool>(this.iCamera != INVALID_ENT_REFERENCE);
		int iDrawFlags1 = bCamera ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT;
		int iDrawFlags2 = bCamera ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED;
		
		mMenu.AddItem("x", "Camera Options", ITEMDRAW_DISABLED);
		mMenu.AddItem("x", " ------------ ", ITEMDRAW_DISABLED);
		mMenu.AddItem("0", "Spawn Camera", iDrawFlags1);
		mMenu.AddItem("1", "Kill Camera", iDrawFlags2);
		mMenu.AddItem("x", " ------------ ", ITEMDRAW_DISABLED);
		mMenu.AddItem("2", "Camera Position", iDrawFlags2);
		mMenu.AddItem("3", "Camera Angle", iDrawFlags2);
		mMenu.AddItem("4", "Camera Track", iDrawFlags2);
		
		mMenu.Display(this.iIndex, MENU_TIME_FOREVER);
		this.mCurrentMenu = mMenu;
	}
	public void DisplayCameraPositionMenu()
	{
		Menu mMenu = new Menu(Menu_CameraPosition);
		mMenu.SetTitle("Advanced Camera Menu:");
		mMenu.ExitBackButton = true;
		
		char sValue[32];
		float vecPos[3];
		this.GetCameraPos(vecPos);
		Format(sValue, sizeof(sValue), "X: %.0f Y: %.0f Z: %.0f", vecPos[0], vecPos[1], vecPos[2]);
		mMenu.AddItem("x", sValue, ITEMDRAW_DISABLED);
		mMenu.AddItem("x", " ------------ ", ITEMDRAW_DISABLED);
		
		mMenu.AddItem("0", "Increase X by 5");
		mMenu.AddItem("1", "Increase Y by 5");
		mMenu.AddItem("2", "Increase Z by 5");
		
		mMenu.AddItem("3", "Decrease X by 5");
		mMenu.AddItem("4", "Decrease Y by 5");
		mMenu.AddItem("5", "Decrease Z by 5");
		
		mMenu.Display(this.iIndex, MENU_TIME_FOREVER);
		this.mCurrentMenu = mMenu;
	}
	public void DisplayCameraAngleMenu()
	{
		Menu mMenu = new Menu(Menu_CameraAngle);
		mMenu.SetTitle("Advanced Camera Menu:");
		mMenu.ExitBackButton = true;
		
		char sValue[32];
		float vecAng[3];
		this.GetCameraAng(vecAng);
		Format(sValue, sizeof(sValue), "Y: %.0f Z: %.0f X: %.0f", vecAng[0], vecAng[1], vecAng[2]);
		mMenu.AddItem("x", sValue, ITEMDRAW_DISABLED);
		mMenu.AddItem("x", " ------------ ", ITEMDRAW_DISABLED);
		
		mMenu.AddItem("0", "Increase Y by 5");
		mMenu.AddItem("1", "Increase Z by 5");
		mMenu.AddItem("2", "Increase X by 5");
		
		mMenu.AddItem("3", "Decrease Y by 5");
		mMenu.AddItem("4", "Decrease Z by 5");
		mMenu.AddItem("5", "Decrease X by 5");
		
		mMenu.Display(this.iIndex, MENU_TIME_FOREVER);
		this.mCurrentMenu = mMenu;
	}
	public void DisplayCameraTrackMenu()
	{
		Menu mMenu = new Menu(Menu_CameraTrack);
		mMenu.SetTitle("Advanced Camera Menu:");
		mMenu.ExitBackButton = true;
		
		char sValue[16];
		bool bTracking = this.bCameraTrack;
		Format(sValue, sizeof(sValue), "Track: %s", bTracking ? "On" : "Off");
		mMenu.AddItem("x", sValue, ITEMDRAW_DISABLED);
		mMenu.AddItem("x", " ------------ ", ITEMDRAW_DISABLED);
		
		mMenu.AddItem("0", "Enable Camera Track", bTracking ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
		mMenu.AddItem("1", "Disable Camera Track", bTracking ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
		
		mMenu.Display(this.iIndex, MENU_TIME_FOREVER);
		this.mCurrentMenu = mMenu;
	}
	
	public void ParentCamera(int iEntity = INVALID_ENT_REFERENCE, bool bParent = true)
	{
		if (iEntity == INVALID_ENT_REFERENCE)
			iEntity = this.iCamera; // Failsafe check.
		
		if (iEntity != INVALID_ENT_REFERENCE)
		{
			/*if (bParent)
			{
				SetVariantString("!activator");
				AcceptEntityInput(iEntity, "SetParent", this.iIndex);
			}
			else
			{
				AcceptEntityInput(iEntity, "ClearParent");
			}*/
		}
	}
	public void MoveCamera(int iEntity = INVALID_ENT_REFERENCE)
	{
		if (iEntity == INVALID_ENT_REFERENCE)
			iEntity = this.iCamera; // Failsafe check.
		
		if (iEntity != INVALID_ENT_REFERENCE)
		{
			int iClient = this.iIndex;
			float vecPos[3], vecAng[3], vecPosAdd[3], vecAngAdd[3];
			GetClientEyePosition(iClient, vecPos);
			GetClientEyeAngles(iClient, vecAng);
			
			this.GetCameraPos(vecPosAdd);
			this.GetCameraAng(vecAngAdd);
			
			AddVectors(vecPos, vecPosAdd, vecPos);
			AddVectors(vecAng, vecAngAdd, vecAng);
			
			TeleportEntity(iEntity, vecPos, vecAng, NULL_VECTOR);
		}
	}
	public void SpawnCamera()
	{
		int iEntity = CreateEntityByName("point_viewcontrol");
		if (iEntity > MaxClients)
		{
			bool bTrack = this.bCameraTrack;
			if (bTrack)
			{
				char sBuffer[32];
				GetEntPropString(this.iIndex, Prop_Data, "m_iName", sBuffer, sizeof(sBuffer));
				if (sBuffer[0])
					DispatchKeyValue(iEntity, "target", sBuffer);
			}
			
			DispatchKeyValue(iEntity, "spawnflags", bTrack ? "2" : "0");
			DispatchSpawn(iEntity); // Spawn in Camera.
			AcceptEntityInput(iEntity, "Enable", this.iIndex);
			
			this.ToggleThirdPerson(true);
			this.MoveCamera(iEntity);
			this.ParentCamera(iEntity);
			this.iCamera = iEntity;
		}
	}
	public void RemoveCamera(int iEntity = INVALID_ENT_REFERENCE)
	{
		if (iEntity == INVALID_ENT_REFERENCE)
			iEntity = this.iCamera; // Failsafe check.
		
		if (iEntity != INVALID_ENT_REFERENCE)
		{
			AcceptEntityInput(iEntity, "Disable"); // Free the Client.
			RemoveEntity(iEntity); // Kill the Camera.
			
			if (this.CheckClient())
			{
				int iClient = this.iIndex;
				SetClientViewEntity(iClient, iClient); // Reset Camera View to avoid bugs.
				this.ToggleThirdPerson(false);
			}
		}
	}
}

public void OnClientPutInServer(int iClient)
{
	g_iClientCameraRef[iClient] = INVALID_ENT_REFERENCE;
	g_bClientCameraTrack[iClient] = false;
	g_flClientCameraPos[iClient] = view_as<float>({0.0, 0.0, 0.0});
	g_flClientCameraAng[iClient] = view_as<float>({0.0, 180.0, 0.0});
	g_mClientCurrentMenu[iClient] = null;
}

public void OnClientDisconnect(int iClient)
{
	AC_Client Client = new AC_Client(iClient);
	if (Client.iCamera != INVALID_ENT_REFERENCE)
	{
		Client.RemoveCamera();
		OnClientPutInServer(iClient);
	}
}

public Action Command_CameraMenu(int iClient, int iArgs)
{
	AC_Client Client = new AC_Client(iClient);
	if (!Client.CheckClient())
		return Plugin_Handled;
	
	Client.DisplayCameraMenu();
	return Plugin_Handled;
}

public Action Command_CameraSpawn(int iClient, int iArgs)
{
	AC_Client Client = new AC_Client(iClient);
	if (!Client.CheckClient())
		return Plugin_Handled;
	
	if (Client.mCurrentMenu != null)
	{
		Client.SendMessage("[SM] Error! Advanced Camera is open!");
		return Plugin_Handled;
	}
	
	if (Client.iCamera != INVALID_ENT_REFERENCE)
		Client.RemoveCamera();
	else
		Client.SpawnCamera();
	
	return Plugin_Handled;
}

public Action Command_CameraPos(int iClient, int iArgs)
{
	AC_Client Client = new AC_Client(iClient);
	if (!Client.CheckClient())
		return Plugin_Handled;
		
	if (iArgs != 3)
	{
		Client.SendMessage("[SM] Usage: sm_ac_pos <float> <float> <float>");
		return Plugin_Handled;
	}
	if (Client.iCamera == INVALID_ENT_REFERENCE)
	{
		Client.SendMessage("[SM] Error! Camera is missing!");
		return Plugin_Handled;
	}
	if (Client.mCurrentMenu != null)
	{
		Client.SendMessage("[SM] Error! Advanced Camera is open!");
		return Plugin_Handled;
	}
	
	char sBuffer[16];
	for (int i = 0; i < 3; i++)
	{
		GetCmdArg(i + 1, sBuffer, sizeof(sBuffer));
		g_flClientCameraPos[iClient][i] = StringToFloat(sBuffer);
	}
	
	int iEntity = Client.iCamera;
	Client.ParentCamera(iEntity, false);
	Client.MoveCamera(iEntity);
	Client.ParentCamera(iEntity);
	return Plugin_Handled;
}

public Action Command_CameraAng(int iClient, int iArgs)
{
	AC_Client Client = new AC_Client(iClient);
	if (!Client.CheckClient())
		return Plugin_Handled;
		
	if (iArgs != 3)
	{
		Client.SendMessage("[SM] Usage: sm_ac_ang <float> <float> <float>");
		return Plugin_Handled;
	}
	if (Client.iCamera == INVALID_ENT_REFERENCE)
	{
		Client.SendMessage("[SM] Error! Camera is missing!");
		return Plugin_Handled;
	}
	if (Client.mCurrentMenu != null)
	{
		Client.SendMessage("[SM] Error! Advanced Camera is open!");
		return Plugin_Handled;
	}
	
	char sBuffer[16];
	for (int i = 0; i < 3; i++)
	{
		GetCmdArg(i + 1, sBuffer, sizeof(sBuffer));
		g_flClientCameraAng[iClient][i] = StringToFloat(sBuffer);
	}
	
	int iEntity = Client.iCamera;
	Client.ParentCamera(iEntity, false);
	Client.MoveCamera(iEntity);
	Client.ParentCamera(iEntity);
	return Plugin_Handled;
}

public Action Command_CameraTrack(int iClient, int iArgs)
{
	AC_Client Client = new AC_Client(iClient);
	if (!Client.CheckClient())
		return Plugin_Handled;
		
	if (iArgs != 1)
	{
		Client.SendMessage("[SM] Usage: sm_ac_track <0/1>");
		return Plugin_Handled;
	}
	if (Client.iCamera == INVALID_ENT_REFERENCE)
	{
		Client.SendMessage("[SM] Error! Camera is missing!");
		return Plugin_Handled;
	}
	if (Client.mCurrentMenu != null)
	{
		Client.SendMessage("[SM] Error! Advanced Camera is open!");
		return Plugin_Handled;
	}
	
	char sBuffer[16];
	GetCmdArg(1, sBuffer, sizeof(sBuffer));
	g_bClientCameraTrack[iClient] = view_as<bool>(StringToInt(sBuffer));
	
	Client.RemoveCamera(Client.iCamera);
	Client.SpawnCamera();
	return Plugin_Handled;
}

public int Menu_Camera(Menu mMenu, MenuAction mSelection, int iParam1, int iParam2)
{
	if (mSelection == MenuAction_Select)
	{
		AC_Client Client = new AC_Client(iParam1);
		if (Client.CheckClient())
		{
			char sResult[12];
			mMenu.GetItem(iParam2, sResult, sizeof(sResult));
			switch (StringToInt(sResult))
			{
				case 0:
				{
					Client.SpawnCamera();
					Client.DisplayCameraMenu();
				}
				case 1:
				{
					Client.RemoveCamera();
					Client.DisplayCameraMenu();
				}
				
				case 2: Client.DisplayCameraPositionMenu();
				case 3: Client.DisplayCameraAngleMenu();
				case 4: Client.DisplayCameraTrackMenu();
				
				default:
				{
					Client.DisplayCameraMenu();
					Client.SendMessage("[SM] Invalid input on Advanced Camera Menu!");
				}
			}
		}
	}
	else if (mSelection == MenuAction_End) 
	{
		CameraMenuEnd(mMenu);
		delete mMenu;
	}
}

public int Menu_CameraPosition(Menu mMenu, MenuAction mSelection, int iParam1, int iParam2)
{
	if (mSelection == MenuAction_Select)
	{
		AC_Client Client = new AC_Client(iParam1);
		if (Client.CheckClient())
		{
			char sResult[12];
			mMenu.GetItem(iParam2, sResult, sizeof(sResult));
			
			int iClient = Client.iIndex;
			switch (StringToInt(sResult))
			{
				case 0: g_flClientCameraPos[iClient][0] += 5.0;
				case 1: g_flClientCameraPos[iClient][1] += 5.0;
				case 2: g_flClientCameraPos[iClient][2] += 5.0;
				case 3: g_flClientCameraPos[iClient][0] -= 5.0;
				case 4: g_flClientCameraPos[iClient][1] -= 5.0;
				case 5: g_flClientCameraPos[iClient][2] -= 5.0;
			}
			
			int iEntity = Client.iCamera;
			Client.ParentCamera(iEntity, false);
			Client.MoveCamera(iEntity);
			Client.ParentCamera(iEntity);
			
			Client.DisplayCameraPositionMenu();
		}
	}
	else if (mSelection == MenuAction_End)
	{
		CameraMenuEnd(mMenu, view_as<bool>(iParam1 == MenuEnd_ExitBack));
		delete mMenu;
	}
}

public int Menu_CameraAngle(Menu mMenu, MenuAction mSelection, int iParam1, int iParam2)
{
	if (mSelection == MenuAction_Select)
	{
		AC_Client Client = new AC_Client(iParam1);
		if (Client.CheckClient())
		{
			char sResult[12];
			mMenu.GetItem(iParam2, sResult, sizeof(sResult));
			
			int iClient = Client.iIndex;
			switch (StringToInt(sResult))
			{
				case 0: g_flClientCameraAng[iClient][0] += 5.0;
				case 1: g_flClientCameraAng[iClient][1] += 5.0;
				case 2: g_flClientCameraAng[iClient][2] += 5.0;
				case 3: g_flClientCameraAng[iClient][0] -= 5.0;
				case 4: g_flClientCameraAng[iClient][1] -= 5.0;
				case 5: g_flClientCameraAng[iClient][2] -= 5.0;
			}
			
			int iEntity = Client.iCamera;
			Client.ParentCamera(iEntity, false);
			Client.MoveCamera(iEntity);
			Client.ParentCamera(iEntity);
			
			Client.DisplayCameraAngleMenu();
		}
	}
	else if (mSelection == MenuAction_End)
	{
		CameraMenuEnd(mMenu, view_as<bool>(iParam1 == MenuEnd_ExitBack));
		delete mMenu;
	}
}

public int Menu_CameraTrack(Menu mMenu, MenuAction mSelection, int iParam1, int iParam2)
{
	if (mSelection == MenuAction_Select)
	{
		AC_Client Client = new AC_Client(iParam1);
		if (Client.CheckClient())
		{
			char sResult[12];
			mMenu.GetItem(iParam2, sResult, sizeof(sResult));
			
			bool bTrack = view_as<bool>(StringToInt(sResult));
			Client.bCameraTrack = bTrack;
			
			int iEntity = Client.iCamera;
			if (iEntity != INVALID_ENT_REFERENCE)
			{
				Client.RemoveCamera();
				Client.SpawnCamera();
			}
			
			Client.DisplayCameraTrackMenu();
		}
	}
	else if (mSelection == MenuAction_End)
	{
		CameraMenuEnd(mMenu, view_as<bool>(iParam1 == MenuEnd_ExitBack));
		delete mMenu;
	}
}

void CameraMenuEnd(Menu mMenu, bool bBack = false)
{
	for (int iClient = MaxClients; iClient > 0; iClient--)
	{
		if (!IsClientInGame(iClient))
			continue;
			
		AC_Client Client = new AC_Client(iClient);
		if (Client.mCurrentMenu == mMenu)
		{
			Client.mCurrentMenu = null;
			
			if (bBack)
				Client.DisplayCameraMenu();
			break;
		}
	}
}

stock void VectorTransform(const float vecOffSet[3], const float vecPos[3], const float vecAng[3], float vecBuffer[3])
{
	float vecFwd[3], vecRight[3], vecUp[3];
	GetAngleVectors(vecAng, vecFwd, vecRight, vecUp);
	
	NormalizeVector(vecFwd, vecFwd);
	NormalizeVector(vecRight, vecRight);
	NormalizeVector(vecUp, vecUp);
	
	ScaleVector(vecRight, vecOffSet[1]);
	ScaleVector(vecFwd, vecOffSet[0]);
	ScaleVector(vecUp, vecOffSet[2]);
	
	vecBuffer[0] = vecPos[0] + vecRight[0] + vecFwd[0] + vecUp[0];
	vecBuffer[1] = vecPos[1] + vecRight[1] + vecFwd[1] + vecUp[1];
	vecBuffer[2] = vecPos[2] + vecRight[2] + vecFwd[2] + vecUp[2];
}