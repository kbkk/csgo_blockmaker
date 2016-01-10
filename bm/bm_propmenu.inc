public ShowPropertyMenu(client)
{
	new Handle:menu = CreateMenu(HandlePropertyMenu);
	decl String:buffer[256], String:tmp[10];

	new block = g_iClCurrentBlock[client];
	new blocktype = g_iBlocks[block];

	SetMenuTitle(menu, "Property of %s", BlockNames[blocktype]);

	Format(buffer, sizeof(buffer), "Top only: %s", g_bTopOnly[block] ? "yes" : "no");
	AddMenuItem(menu, "toponly", buffer);

	for(new i = 0; i < MAXPROPERTIES; i++) {
		IntToString(i, tmp, sizeof(tmp));

		Format(buffer, sizeof(buffer), "%s: %.1f", g_sPropertyName[blocktype][i], g_fPropertyValue[block][i]);
		AddMenuItem(menu, tmp, buffer);
	}


	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public HandlePropertyMenu(Handle:menu, MenuAction:action, client, param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			new block = g_iClCurrentBlock[client];
			new blocktype = g_iBlocks[block];

			switch(param2) {
				case 0: {
					g_bTopOnly[g_iClCurrentBlock[client]] = !g_bTopOnly[g_iClCurrentBlock[client]];
				}
				default:
				{
					decl String:tmp[10], propnum;
					GetMenuItem(menu, param2, tmp, sizeof(tmp));
					propnum = StringToInt(tmp);

					g_iClInputting[client] = propnum;

					PrintToChat(client, "%s\x04 You are setting\x03 %s\x04 of\x03 %s",
					PREFIX, g_sPropertyName[blocktype][propnum], BlockNames[blocktype]);
				}
			}

			ShowPropertyMenu(client);
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}
