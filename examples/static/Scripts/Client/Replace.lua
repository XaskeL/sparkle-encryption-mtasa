-- code from @https://wiki.multitheftauto.com/wiki/EngineReplaceModel

addEventHandler( "onClientResourceStart", resourceRoot, function ( )
	local key = "?YB%|PBmszlk1e4B" 
	
	for assetID = 1, #modelsToReplace do
		local modelData = modelsToReplace[assetID]
		local modelCol = modelData.colFile
		local modelTxd = modelData.txdFile
		local modelDff = modelData.dffFile
		local modelID = modelData.modelID

		if modelCol then
			local colData = engineLoadCOL( fileGetPrivateBuffer( modelData.colFile, key ) )

			if colData then
				engineReplaceCOL(colData, modelID)
			end
		end

		if modelTxd then
			local filteringEnabled = modelData.filteringEnabled
			local txdData = engineLoadTXD( fileGetPrivateBuffer( modelData.txdFile, key ), filteringEnabled)

			if txdData then
				engineImportTXD(txdData, modelID)
			end
		end

		if modelDff then
			local dffData = engineLoadDFF( fileGetPrivateBuffer( modelData.dffFile, key ) )

			if dffData then
				local alphaTransparency = modelData.alphaTransparency
				
				engineReplaceModel(dffData, modelID, alphaTransparency)
			end
		end
		
		collectgarbage( "collect" );
	end
end );