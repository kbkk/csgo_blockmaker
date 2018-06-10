public ShowPropertyMenu(client)
{
	new Handle:menu = CreateMenu(HandlePropertyMenu);
	decl String:buffer[256], String:tmp[16];

	new block = g_iClCurrentBlock[client];
	new blocktype = g_iBlocks[block];

	SetMenuTitle(menu, "Property of %s", BlockNames[blocktype]);

	Format(buffer, sizeof(buffer), "Top only: %s", g_bTopOnly[block] ? "yes" : "no");
	AddMenuItem(menu, "toponly", buffer);

	for(new i = 0; i < MAXPROPERTIES; i++) {
		IntToString(i, tmp, sizeof(tmp));

		if(g_sPropertyName[blocktype][i][0] == EOS)
			break;

		Format(buffer, sizeof(buffer), "%s: %.1f", g_sPropertyName[blocktype][i], g_fPropertyValue[block][i]);
		AddMenuItem(menu, tmp, buffer);
	}

	if(blocktype == _:LOCK && g_Lock[block] != null) {
		float values[3];
		int type;
		g_Lock[block].GetValue("blocktype", type);
		g_Lock[block].GetArray("properties", values, 3);

		Format(tmp, sizeof tmp, "2137");
		Format(buffer, sizeof(buffer), "type: %s", BlockNames[type]);
		AddMenuItem(menu, tmp, buffer);

		for(int i = 0; i < MAXPROPERTIES; i++) {
			Format(tmp, sizeof tmp, "%i", i+100);

			if(g_sPropertyName[type][i][0] == EOS)
				break;

			Format(buffer, sizeof(buffer), "%s: %.1f", g_sPropertyName[type][i], values[i]);
			AddMenuItem(menu, tmp, buffer);
		}
	}

	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public HandlePropertyMenu(Handle:menu, MenuAction:action, client, param2)
{
	bool refreshMenu = true;

	switch (action)
	{
		case MenuAction_Select:
		{
			new block = g_iClCurrentBlock[client];
			new blocktype = g_iBlocks[block];

			switch(param2) {
				case 0: {
					g_bTopOnly[block] = !g_bTopOnly[block];
				}
				default:
				{
					decl String:tmp[16], propnum;
					GetMenuItem(menu, param2, tmp, sizeof(tmp));
					propnum = StringToInt(tmp);

					if(propnum == 0 && blocktype == _:WEAPON)
					{
						WeaponsMenu(client);
						refreshMenu = false;
					}
					else 
					{
						g_iClInputting[client] = propnum;
					}

					//PrintToChat(client, "%s\x04 You are setting\x03 %s\x04 of\x03 %s",
					//PREFIX, g_sPropertyName[blocktype][propnum], BlockNames[blocktype]);
				}
			}

			if(refreshMenu) {
				ShowPropertyMenu(client);
			}
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}

public void WeaponsMenu(client) {
	new Handle:hMenu = CreateMenu(WeaponsMenu_Handle);
	SetMenuTitle(hMenu, "Property - Choose Weapon");
	
	char tmp[16];
	for (int i = 0; i < ALL_WEAPONS; i++) {
		IntToString(i, tmp, sizeof tmp);
		AddMenuItem(hMenu, tmp, g_sWeapons[i][7]);
	}
	
	SetMenuExitButton(hMenu, true);
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
}

public WeaponsMenu_Handle(Handle hMenu, MenuAction action, client, param2) {
	if(action == MenuAction_Select){
		new block = g_iClCurrentBlock[client];
		new blocktype = g_iBlocks[block];
		
		char tmp[16];
		float weapon;
		GetMenuItem(hMenu, param2, tmp, sizeof tmp);
		weapon = StringToFloat(tmp);

		g_fPropertyValue[block][0] = weapon;
	}  
	if(action == MenuAction_End){
		CloseHandle(hMenu);
	}

	ShowPropertyMenu(client);
}