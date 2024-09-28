modelsToReplace = {
	{ -- replace object
		colFile = "object.colrw";
		txdFile = "object.txdrw";
		dffFile = "object.dffrw";
		modelID = 1337;
		alphaTransparency = false;
		filteringEnabled = true; -- Если объект имеет всякое прозрачное; то при true будет последним в render ordering
	};
	
	{ -- replace vehicle
		colFile = false; -- if .col is not present set to false/nil
		txdFile = "vehicle.txdrw";
		dffFile = "vehicle.dffrw";
		modelID = 434;
		alphaTransparency = false;
		filteringEnabled = true;
	};
	
	{ -- replace skin
		colFile = false;
		txdFile = "skin.txdrw";
		dffFile = "skin.dffrw";
		modelID = 57;
		alphaTransparency = false;
		filteringEnabled = true;
	};
}