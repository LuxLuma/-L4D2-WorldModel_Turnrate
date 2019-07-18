#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#pragma newdecls required


#define PLUGIN_VERSION "1.0"

Handle hCvar_TurnRate = null;

Handle hCvar_FaceFrontTime 		= null;
Handle hCvar_FeetMaxYawRate 	= null;
Handle hCvar_FeetYawRate 		= null;
Handle hCvar_FeetYawRate_Max 	= null;

char sTurningRate[16];

char sFeetMaxYawRate[16];
char sFeetYawRate[16];
char sFeetYawRate_Max[16];


public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if(GetEngineVersion() != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public Plugin myinfo =
{
	name = "L4D2_WorldModel_Turnrate_visual",
	author = "Lux",
	description = "By default restores l4d1 world model turnrate this is just visual and server knows nothing about it meaning curve rocks will work anyother slow turning bugs will still happen, since server knows nothing.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=2641104"
};

public void OnPluginStart()
{
	CreateConVar("worldmodel_turnrate_visual_version", PLUGIN_VERSION, "", FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_NOTIFY);
	
	hCvar_TurnRate = CreateConVar("worldmodel_turnrate", "2160", "Speed at which worldmodel turns to match viewmodel pitch angle, default l4d2 speed is [100], default of [2160] closely matches l4d1,", FCVAR_NOTIFY, true, 1.0, true, 9999999.0);
	hCvar_FaceFrontTime = FindConVar("mp_facefronttime");
	hCvar_FeetMaxYawRate = FindConVar("mp_feetmaxyawrate");
	hCvar_FeetYawRate = FindConVar("mp_feetyawrate");
	hCvar_FeetYawRate_Max = FindConVar("mp_feetyawrate_max");
	
	HookConVarChange(hCvar_TurnRate, eConvarChanged);
	HookConVarChange(hCvar_FaceFrontTime, eConvarChanged);
	HookConVarChange(hCvar_FeetMaxYawRate, eConvarChanged);
	HookConVarChange(hCvar_FeetYawRate, eConvarChanged);
	HookConVarChange(hCvar_FeetYawRate_Max, eConvarChanged);
	
	AutoExecConfig(true, "L4D2_WorldModel_Turnrate");
	
	CvarsChanged();
}

public void eConvarChanged(Handle hCvar, const char[] sOldVal, const char[] sNewVal)
{
	CvarsChanged();
}

void CvarsChanged()
{
	GetConVarString(hCvar_TurnRate, sTurningRate, sizeof(sTurningRate));
	GetConVarString(hCvar_FeetMaxYawRate, sFeetMaxYawRate, sizeof(sFeetMaxYawRate));
	GetConVarString(hCvar_FeetYawRate, sFeetYawRate, sizeof(sFeetYawRate));
	GetConVarString(hCvar_FeetYawRate_Max, sFeetYawRate_Max, sizeof(sFeetYawRate_Max));
}

public void OnClientPutInServer(int iClient)
{
	if(IsFakeClient(iClient) || !IsClientInGame(iClient))
		return;
	
	SetChangedTurnSpeed(iClient);
	SDKHook(iClient, SDKHook_PostThinkPost, PostThinkPost);
}


public void PostThinkPost(int iClient)
{
	static bool bShouldResetTurnSpeed[MAXPLAYERS+1];
	
	if(GetClientTeam(iClient) != 3 || !IsPlayerAlive(iClient) || GetEntProp(iClient, Prop_Send, "m_zombieClass", 1) != 8)
	{
		if(bShouldResetTurnSpeed[iClient])
		{
			bShouldResetTurnSpeed[iClient] = false;
			SetChangedTurnSpeed(iClient);
		}
		return;
	}
	
	switch(GetEntProp(iClient, Prop_Send, "m_nSequence", 2))
	{
		case 49, 50, 51://send clients default cvar vals so curve rock like vanilla will show everone at default server turnspeed for the client, everyone else will remain untouched.
		{
			if(bShouldResetTurnSpeed[iClient])
				return;
			
			bShouldResetTurnSpeed[iClient] = true;
			SetDefaultTurnSpeed(iClient);
			return;
		}
	}
	
	if(bShouldResetTurnSpeed[iClient])
	{
		bShouldResetTurnSpeed[iClient] = false;
		SetChangedTurnSpeed(iClient);
	}
	return;
}


void SetChangedTurnSpeed(int iClient)
{
	SendConVarValue(iClient, hCvar_FaceFrontTime, "-1");
	SendConVarValue(iClient, hCvar_FeetMaxYawRate, sTurningRate);
	SendConVarValue(iClient, hCvar_FeetYawRate, sTurningRate);
	SendConVarValue(iClient, hCvar_FeetYawRate_Max, sTurningRate);
}

void SetDefaultTurnSpeed(int iClient)
{
	SendConVarValue(iClient, hCvar_FaceFrontTime, "2");
	SendConVarValue(iClient, hCvar_FeetMaxYawRate, sFeetMaxYawRate);
	SendConVarValue(iClient, hCvar_FeetYawRate, sFeetYawRate);
	SendConVarValue(iClient, hCvar_FeetYawRate_Max, sFeetYawRate_Max);
}