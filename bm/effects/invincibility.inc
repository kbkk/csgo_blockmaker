public Action INVINCIBLITY_end(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);

	if(!client)
		return Plugin_Stop;

	g_PlayerEffects[client][Invincibility][active] = false;

	SetEntityRenderMode(client, RENDER_NORMAL);
	SetEntityRenderColor(client, 255, 255, 255, 255);

	SDKUnhook(client, SDKHook_OnTakeDamage, INVINCIBLITY_OnTakeDamage);
	PrintToChat(client, "\x03%s\x04 Invincibility\x01 has worn off.", CHAT_TAG);

	return Plugin_Stop;
}

public Action INVINCIBLITY_cdEnd(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);

	if(!client)
		return Plugin_Stop;

	g_PlayerEffects[client][Invincibility][canUse] = true;
	PrintToChat(client, "\x03%s\x04 Invincibility\x01 cooldown has ended.", CHAT_TAG);

	return Plugin_Stop;
}

public Action INVINCIBLITY_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, &damagetype)
{
	return g_PlayerEffects[victim][Invincibility][active]
		? Plugin_Handled : Plugin_Continue;
}
