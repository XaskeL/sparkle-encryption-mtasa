local files = {
	-- Сюда добавлять только файлы что имеют compiled = true
	[411] = { path = ":germany/c63cope", pass = "48?%~BSHHF6jFqld" };
}

addEventHandler("onResourceStart", resourceRoot, function()
	for i, v in pairs ( files ) do
		fileSetPrivate( v.path .. ".dffrw", v.pass );
		fileSetPrivate( v.path .. ".txdrw", v.pass );
	end
end)

-- Получение пароля клиентом
addEvent("getReplaceInfo", true)
addEventHandler("getReplaceInfo", resourceRoot, function(model, forceReplace)
	triggerClientEvent(client, "takeReplaceInfo", resourceRoot, model, files[model], forceReplace)
end)

-- Вкл/выкл дебаг
addCommandHandler("showmodelstats", function(playerSource)
	triggerClientEvent(playerSource, "toggleModelStats", resourceRoot)
end, true, false)

-- Предпрогрузка всех моделей
addCommandHandler("preloadmodels", function(playerSource)
	triggerClientEvent(playerSource, "pc_replacer.preloadAllCars", resourceRoot)
end)
