public ShowReadOnlyPropertyPanelAiming(client) {
	new ent = GetClientAimTarget2(client, false);

	if(!IsValidBlock(ent))
		return;

	ShowReadOnlyPropertyPanel(client, ent);
}

public ShowReadOnlyPropertyPanel(client, block) {
	decl String:buffer[256];

	new blocktype = g_iBlocks[block];

	Panel panel = new Panel();

	Format(buffer, sizeof(buffer), "%s", BlockNames[blocktype]);
	panel.SetTitle(buffer);

	Format(buffer, sizeof(buffer), "Top only: %s", g_bTopOnly[block] ? "yes" : "no");
	panel.DrawItem(buffer);

	for(new i = 0; i < MAXPROPERTIES; i++) {

		if(g_sPropertyName[blocktype][i][0] == EOS)
			break;

		Format(buffer, sizeof(buffer), "%s: %.1f", g_sPropertyName[blocktype][i], g_fPropertyValue[block][i]);
		panel.DrawItem(buffer);
	}

	panel.Send(client, EmptyHandler, 3);

	delete panel;
}

public EmptyHandler(Menu menu, MenuAction action, int param1, int param2) { }
