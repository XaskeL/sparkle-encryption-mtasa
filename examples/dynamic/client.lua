
local debugEnabled = false
local criticalUnloadTime = 60000
local alwaysInMemoryCount = 0
local configFile = "config.json"

-- ===============     Слежение за встримом/выстримом машин     ===============
local loadedVehiclesCount = {}		-- Количество встримленных машин каждой модели
local vehicleIsReplacing = false	-- Для игнора перестрима конкретной машины

function onStreamIn(vehicle)
	local model = getElementModel(vehicle)
	if (vehicleIsReplacing ~= model) then
		loadedVehiclesCount[model] = (loadedVehiclesCount[model] or 0) + 1
		addToReplaceQueue(model, vehicle)
		-- iprint("streamedIn", model)
	else
		vehicleIsReplacing = false
		-- iprint("streamInSuppressed", model)
	end
end

function onStreamOut(vehicle, model)
	model = model or getElementModel(vehicle)
	if (vehicleIsReplacing ~= model) then
		loadedVehiclesCount[model] = (loadedVehiclesCount[model] or 0) - 1
		if (loadedVehiclesCount[model] < 1) then
			loadedVehiclesCount[model] = nil
			addToRestoreQueue(model)
		end
		-- iprint("streamedOut", model)
	else
		-- iprint("streamOutSuppressed", model)
	end
end

-- События встрима
addEventHandler("onClientResourceStart", resourceRoot, function()
	engineSetAsynchronousLoading(true, true) 
	for _, vehicle in ipairs(getElementsByType("vehicle", root, true)) do
		onStreamIn(vehicle)
	end
	alwaysInMemoryCount = loadLowerLimit() or alwaysInMemoryCount
end)
addEventHandler("onClientElementStreamIn", root, function()
	if (getElementType(source) == "vehicle") then
		onStreamIn(source)
	end
end)

-- События выстрима
addEventHandler("onClientElementStreamOut", root, function()
	if (getElementType(source) == "vehicle") then
		onStreamOut(source)
	end
end)
addEventHandler("onClientElementDestroy", root, function()
	if (getElementType(source) == "vehicle") and isElementStreamedIn(source) then
		onStreamOut(source)
	end
end)

-- Потому что некоторые машины зависают в виде застримленных
function checkForStuckVehicles()
	local fullCount, newCount = 0, 0
	for model, count in pairs(loadedVehiclesCount) do
		fullCount = fullCount + count
		for i = 1, count do
			onStreamOut(nil, model)
		end
	end
	loadedVehiclesCount = {}
	for _, vehicle in ipairs(getElementsByType("vehicle", root, true)) do
		onStreamIn(vehicle)
	end
	for model, count in pairs(loadedVehiclesCount) do
		newCount = newCount + count
	end
	if (debugEnabled) and (newCount < fullCount) then
		iprint("stuck vehicles removed:", fullCount-newCount)
	end
end
local stuckVehiclesTimer = setTimer(checkForStuckVehicles, 30000, 0)

-- Потому что машина перестримливается при замене
function suppressVehicleStreamHandlers(model)
	vehicleIsReplacing = model
end

-- ===============     Управление очередями     ===============
local replaceQueue = {}		-- Очередь моделей на замену
local replacedModels = {}	-- Замененные модели
local notNeededModels = {}	-- Машины, которые больше не нужны

function addToReplaceQueue(model, element)
	if (not replaceQueue[model]) and (not replacedModels[model]) then
		replaceQueue[model] = true
	end
	if not (replacedModels[model]) then
		setElementAlpha(element, 0)
	end
	notNeededModels[model] = nil
end
function isModelInReplaceQueue(model)
	return replaceQueue[model]
end
function onVehicleReplaced(model)
	replaceQueue[model] = nil
	replacedModels[model] = true
	for _, vehicle in ipairs(getElementsByType("vehicle", root)) do	-- Здесь возможны багули, если что-то где-то должно оставаться не в полной альфе
		if (getElementModel(vehicle) == model) then
			setElementAlpha(vehicle, 255)
		end
	end
end

function addToRestoreQueue(model)
	replaceQueue[model] = nil
	if (replacedModels[model]) then
		notNeededModels[model] = getTickCount()
	end
end

-- Проверка очереди на выгрузку
addEventHandler("onClientPreRender", root, function()
	local criticalTime = getTickCount()-criticalUnloadTime
	local minimumTime = getTickCount()
	local modelToRestore
	for model, state in pairs(replaceQueue) do
		if (state == true) then
			replaceQueue[model] = "waiting"
			replaceModel(model)
			break
		end
	end
	for model, lastUseTime in pairs(notNeededModels) do
		if (lastUseTime < criticalTime) and (lastUseTime < minimumTime) then
			modelToRestore = model
			minimumTime = lastUseTime
		end
	end
	if (modelToRestore) and (count(replacedModels) > alwaysInMemoryCount) then
		restoreModel(modelToRestore)
		replacedModels[modelToRestore] = nil
		notNeededModels[modelToRestore] = nil
	end
end)

function isModelReplaced(model)
	return replacedModels[model]
end

-- ===============     Замена/восстановление машин     ===============
local dffs = {}	-- Элементы дфф и тхд
local txds = {}
local modelStats = {}
-- Замена модели простой/закомпиленной
function replaceModel(model, forceReplace)
	local carData = files[model]
	if (carData) then
		if (not carData.compiled) then
			local startTime = getTickCount()
			replaceVehicle(model, carData.path, false, {pass=nil, count=nil, decryptFunc=nil}, forceReplace)
		else
			triggerServerEvent("getReplaceInfo", resourceRoot, model, forceReplace)
		end
	else
		onVehicleReplaced(model)
	end
end
function onReplaceModelCallback(model, cryptData, forceReplace)
	if isModelInReplaceQueue(model) or (forceReplace) then
		local startTime = getTickCount()
		replaceVehicle(model, files[model].path, true, cryptData, forceReplace)
	end
end
addEvent("takeReplaceInfo", true)
addEventHandler("takeReplaceInfo", resourceRoot, onReplaceModelCallback)

-- Собственно замена модели
function replaceVehicle(model, path, compiled, cryptData, forceReplace)
	if isModelInReplaceQueue(model) or (forceReplace) then
		suppressVehicleStreamHandlers(model)
		modelStats[model] = {txdLoad = getTickCount()}
		if (not compiled) then
			txds[model] = engineLoadTXD(path..".txd", true)
		else
			txds[model] = engineLoadTXD(fileGetPrivateBuffer(path..".txdrw", cryptData.pass), true)
		end
		modelStats[model].txdLoad = getTickCount() - modelStats[model].txdLoad
		setTimer(replaceVehicle2, 50, 1, model, path, compiled, cryptData, forceReplace)
	end
end
function replaceVehicle2(model, path, compiled, cryptData, forceReplace)
	if isModelInReplaceQueue(model) or (forceReplace) then
		modelStats[model].txdImport = getTickCount()
		if isElement(txds[model]) then
			engineImportTXD(txds[model], model)
		end
		modelStats[model].txdImport = getTickCount() - modelStats[model].txdImport
		setTimer(replaceVehicle3, 50, 1, model, path, compiled, cryptData, forceReplace)
	end
end
function replaceVehicle3(model, path, compiled, cryptData, forceReplace)
	if isModelInReplaceQueue(model) or (forceReplace) then
		modelStats[model].dffLoad = getTickCount()
		if (not compiled) then
			dffs[model] = engineLoadDFF(path..".dff", model)
		else
			dffs[model] = engineLoadDFF(fileGetPrivateBuffer(path..".dffrw", cryptData.pass))
		end
		modelStats[model].dffLoad = getTickCount() - modelStats[model].dffLoad
		setTimer(replaceVehicle4, 50, 1, model, compiled, forceReplace)
	end
end
function replaceVehicle4(model, compiled, forceReplace)
	if isModelInReplaceQueue(model) or (forceReplace) then
		modelStats[model].dffReplace = getTickCount()
		if isElement(dffs[model]) then
			engineReplaceModel(dffs[model], model)
		end
		modelStats[model].dffReplace = getTickCount() - modelStats[model].dffReplace
		onVehicleReplaced(model)
		if (debugEnabled) then iprint("replaced", model, modelStats[model].txdLoad, modelStats[model].txdImport, compiled, modelStats[model].dffLoad, modelStats[model].dffReplace) end
		modelStats[model] = nil
		collectgarbage()
	end
end

-- Восстановление модели
function restoreModel(model)
	engineRestoreModel(model)
	if isElement(dffs[model]) then destroyElement(dffs[model]) end
	if isElement(txds[model]) then destroyElement(txds[model]) end
	dffs[model] = nil
	txds[model] = nil
	collectgarbage()
end
addEventHandler("onClientResourceStop", resourceRoot, function()
	for model, _ in pairs(files) do
		restoreModel(model)
	end
end)



-- ===============     Управление нижним лимитом моделей     ===============
function loadLowerLimit()
	if fileExists(configFile) then
		local file = fileOpen(configFile, true)
		if (not file) then return false end
		local data = fromJSON(fileRead(file, fileGetSize(file)))
		fileClose(file)
		if (not data) or (type(data) ~= "table") then return false end
		
		if tonumber(data.alwaysInMemoryCount) and (data.alwaysInMemoryCount >= 0) then
			return data.alwaysInMemoryCount
		end
	end
	return false
end

function storeLowerLimit(value)
	local data = {}
	data.alwaysInMemoryCount = value
	
	local file = fileCreate(configFile)
	if (file) then
		fileWrite(file, toJSON(data, true))
		fileClose(file)
	end
end

addCommandHandler("setmodellimit", function(_, value)
	value = tonumber(value)
	if (value) then
		storeLowerLimit(value)
		alwaysInMemoryCount = value
		outputChatBox("Model limit set to "..value)
	else
		outputChatBox("Use setmodellimit <number> to set amount of non-unloading cars")
	end
end, false)


-- ===============     Отладка     ===============
-- ===============     Прогрузка всех машин и отключение реакции на события     ===============
local preLoaded = false
addEvent("pc_replacer.preloadAllCars", true)
addEventHandler("pc_replacer.preloadAllCars", resourceRoot, function()
	if (not preLoaded) then
		local events = {["onClientResourceStart"] = resourceRoot, ["onClientElementStreamIn"] = root, ["onClientElementStreamOut"] = root, ["onClientElementDestroy"] = root}
		for eventName, attachedTo in pairs(events) do
			removeAllEventHandlers(eventName, attachedTo)
		end
		
		local timerValue = 50
		for model, _ in pairs(files) do
			setTimer(replaceModel, timerValue, 1, model, true)
			timerValue = timerValue + 50
		end
		if isTimer(stuckVehiclesTimer) then killTimer(stuckVehiclesTimer) end
		
		preLoaded = true
		outputChatBox("Запущена прогрузка всех моделей, реакция на эвенты отключена")
	else
		outputChatBox("Все машины уже прогружены!")
	end
end)

function removeAllEventHandlers(eventName, attachedTo)
	for _, func in ipairs(getEventHandlers(eventName, attachedTo)) do
		removeEventHandler(eventName, attachedTo, func) 
	end
end


-- ===============     Показ статистики на экране и выгрузка в файл     ===============
local secondsPassedCache = {}
-- Статистика на экране
function onClientRender()
	if (debugEnabled) then
		local screenW, screenH = guiGetScreenSize()
		local text = {
			"loadedVehiclesCount ("..count(loadedVehiclesCount)..") = "..inspect(loadedVehiclesCount),
			"replaceQueue ("..count(replaceQueue)..") = "..inspect(replaceQueue),
			"replacedModels ("..count(replacedModels)..") = "..inspect(replacedModels),
			"notNeededModels ("..count(notNeededModels)..") = "..inspect(notNeededModels),
		}
		local screenShift = 300
		for _, row in ipairs(text) do
			draw(row, screenShift)
			screenShift = screenShift + 150
		end
		
		local secondsPassed = {}
		local currentTicks = getTickCount()
		for model, time in pairs(notNeededModels) do
			secondsPassed[model] = math.floor((currentTicks-time)/1000)
		end
		draw("secondsPassed ("..count(secondsPassed)..") = "..inspect(secondsPassed), screenShift)
		secondsPassedCache = secondsPassed
	end
end
function draw(text, screenShift)
	dxDrawText(text, screenShift, 100-1, screenShift+150-1, screenH, 0xFF000000, 1, "default", "right")
	dxDrawText(text, screenShift, 100-1, screenShift+150+1, screenH, 0xFF000000, 1, "default", "right")
	dxDrawText(text, screenShift, 100+1, screenShift+150-1, screenH, 0xFF000000, 1, "default", "right")
	dxDrawText(text, screenShift, 100+1, screenShift+150+1, screenH, 0xFF000000, 1, "default", "right")
	dxDrawText(text, screenShift, 100, screenShift+150, screenH, 0xFFFFFFFF, 1, "default", "right")
end

-- Вывод статистики в файл
local headerWritten = false
function calculateStats()
	if (debugEnabled) then
		if (headerWritten) then
			local timestamp = getRealTime().timestamp
			local ticks = getTickCount()
			local maxPassed = 0
			local averagePassed = 0
			local countSecondsPassed = count(secondsPassedCache)
			local countNotNeededModels = count(notNeededModels)
			local countReplacedModels = count(replacedModels)
			for model, value in pairs(secondsPassedCache) do
				averagePassed = averagePassed + value
				if (maxPassed < value) then
					maxPassed = value
				end
			end
			if (countSecondsPassed > 0) then
				averagePassed = averagePassed/countSecondsPassed
			end
			fileWriteLine("statistics.csv", tostring(timestamp), ";", tostring(ticks), ";",
				tostring(count(loadedVehiclesCount)), ";", tostring(count(replaceQueue)), ";", tostring(countReplacedModels), ";", tostring(countNotNeededModels), ";", tostring(countSecondsPassed), ";",
				tostring(maxPassed), ";", string.gsub(tostring(averagePassed), "[.]", ","), ";", tostring(countReplacedModels-countNotNeededModels)
			)
			fileWriteLine("tableContents.csv", tostring(timestamp), ";", tostring(ticks), ";",
				tableToString(loadedVehiclesCount, ",", "="), ";", tableToString(replaceQueue, ",", "="), ";", tableToString(replacedModels, ",", "="), ";",
				tableToString(notNeededModels, ",", "="), ";", tableToString(secondsPassedCache, ",", "=")
			)
			-- outputConsole("Stats written")
		else
			fileWriteLine("statistics.csv", "timestamp;getTickCount;loadedVehiclesCount;replaceQueue;replacedModels;notNeededModels;secondsPassed;maxPassed;averagePassed;replacedAndNotNeeded")
			fileWriteLine("tableContents.csv", "timestamp;getTickCount;loadedVehiclesCount;replaceQueue;replacedModels;notNeededModels;secondsPassed")
			headerWritten = true
		end
	end
end

-- Переключение режима отладки
local statsTimer
function toggleDebug()
	debugEnabled = not debugEnabled
	if (debugEnabled) then
		addEventHandler("onClientRender", root, onClientRender)
		statsTimer = setTimer(calculateStats, 10000, 0)
	else
		removeEventHandler("onClientRender", root, onClientRender)
		killTimer(statsTimer)
		secondsPassedCache = {}
	end
end
addEvent("toggleModelStats", true)
addEventHandler("toggleModelStats", resourceRoot, toggleDebug)



-- ===============     Вспомогательные функции     ===============
function count(array)
	local count = 0
	for _, _ in pairs(array) do
		count = count + 1
	end
	return count
end

function fileWriteLine(fileName, ...)
	if not fileExists(fileName) then
		local created = fileCreate(fileName)
		if (created) then
			fileClose(created)
		else
			outputConsole("Unable to create "..tostring(fileName))
		end
	end
	local file = fileOpen(fileName, false)
	if (file) then
		fileSetPos(file, fileGetSize(file))
		fileWrite(file, ...)
		fileWrite(file, "\n")
		fileClose(file)  
	else
		outputConsole("Unable to open "..tostring(fileName))
	end
end

function tableToString(Table, rowSeparator, keyValueSeparator)
	local temp = {}
	for key, value in pairs(Table) do
		table.insert(temp, tostring(key)..keyValueSeparator..tostring(value))
	end
	return table.concat(temp, rowSeparator)
end
