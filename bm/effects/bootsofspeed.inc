public Action BOOTS_OF_SPEED_end(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);

	if(!client)
		return Plugin_Stop;

	g_PlayerEffects[client][BootsOfSpeed][active] = false;
	SetEntPropFloat(client, Prop_Send, "m_flVelocityModifier", 1.0);

	PrintToChat(client, "\x03%s\x04 Boots of speed\x01 has worn off.", CHAT_TAG);

	return Plugin_Stop;
}

public Action BOOTS_OF_SPEED_cdEnd(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);

	if(!client)
		return Plugin_Stop;

	g_PlayerEffects[client][BootsOfSpeed][canUse] = true;
	PrintToChat(client, "\x03%s\x04 Boots of speed\x01 cooldown has ended.", CHAT_TAG);

	return Plugin_Stop;
}
