public ShowReadOnlyPropertyPanelAiming(client) {
	new ent = GetClientAimTarget2(client, false);

	if(!IsValidBlock(ent) || g_iTeleporters[ent] != -1)
		return;

	ShowReadOnlyPropertyPanel(client, ent);
}

public ShowReadOnlyPropertyPanel(client, block) {

	decl String:buffer[256];
	new blocktype = g_iBlocks[block];
	Panel panel = new Panel();
	int lockBlocktype;

	Format(buffer, sizeof(buffer), "%s", BlockNames[blocktype]);

	if(blocktype == _:LOCK && g_Lock[block] != null) {
		g_Lock[block].GetValue("blocktype", lockBlocktype);

		Format(buffer, sizeof(buffer), "%s (%s)", BlockNames[blocktype], BlockNames[lockBlocktype]);
	}

	panel.SetTitle(buffer);

	Format(buffer, sizeof(buffer), "Top only: %s", g_bTopOnly[block] ? "yes" : "no");
	panel.DrawItem(buffer);

	for(int i = 0; i < MAXPROPERTIES; i++) {

		if(g_sPropertyName[blocktype][i][0] == EOS)
			break;

		float propValue = g_fPropertyValue[block][i];

		if(blocktype == _:WEAPON && i == 0)
		{
			Format(
				buffer,
				sizeof buffer,
				"%s: %s",
				g_sPropertyName[blocktype][i],
				g_sWeapons[RoundFloat(propValue)]
			);
		}
		else
		{
			Format(buffer, sizeof(buffer), "%s: %.1f", g_sPropertyName[blocktype][i], propValue);
		}

		panel.DrawItem(buffer);
	}

	if(blocktype == _:LOCK && g_Lock[block] != null) {
		float values[3];
		g_Lock[block].GetArray("properties", values, 3);

		for(int i = 0; i < MAXPROPERTIES; i++) {
			if(g_sPropertyName[lockBlocktype][i][0] == EOS)
				break;

			Format(buffer, sizeof(buffer), "%s: %.1f", g_sPropertyName[lockBlocktype][i], values[i]);
			panel.DrawItem(buffer);
		}
	}

	panel.Send(client, EmptyHandler, 3);

	delete panel;
}

public EmptyHandler(Menu menu, MenuAction action, int param1, int param2) { }
