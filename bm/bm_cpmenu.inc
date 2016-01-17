new Float:g_vClCheckpoint[MAXPLAYERS + 1][3];

public ShowCheckpointMenu(client)
{
	new Handle:menu = CreateMenu(HandleCheckpointMenu);

	SetMenuTitle(menu, "Checkpoint menu");

	AddMenuItem(menu, "cp_create", "Create a checkpoint");
	AddMenuItem(menu, "cp_load", "Load checkpoint");

	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public HandleCheckpointMenu(Handle:menu, MenuAction:action, client, param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			decl String:item[32];
			GetMenuItem(menu, param2, item, sizeof(item));

			/* PAWN cannot into switch string comparisions */
			if(StrEqual(item, "cp_create")) {
				GetClientAbsOrigin(client, g_vClCheckpoint[client]);
				PrintToChat(client, "%s A checkpoint has been created!", PREFIX);
			}

			else if(StrEqual(item, "cp_load")) {
				TeleportEntity(client, g_vClCheckpoint[client], NULL_VECTOR, NULL_VECTOR);
				PrintToChat(client, "%s Checkpoint has been loaded!", PREFIX);
			}

			ShowCheckpointMenu(client);
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}
