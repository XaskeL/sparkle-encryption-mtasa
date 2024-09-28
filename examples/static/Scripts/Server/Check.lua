addEventHandler( "onResourceStart", resourceRoot, function ( )
	local restart = false
	local xml = xmlLoadFile( "meta.xml" )
	
	for i, child in ipairs( xmlNodeGetChildren( xml ) ) do
		if ( xmlNodeGetName( child ) == "file" ) then
			local isModel = false
			local filePath= xmlNodeGetAttributes( child ).src
			
			for i, fileType in ipairs( { ".dff", ".txd", ".col" } ) do
				if string.find( filePath, fileType ) and not string.find( filePath, fileType .. "rw" ) then
					isModel = true;
				end
			end
			
			if ( isModel ) then
				fileSetPrivate( filePath, "?YB%|PBmszlk1e4B" );
				xmlNodeSetAttribute( child, "src", filePath .. "rw" )
				
				restart = true
			end
		end
	end
	
	xmlSaveFile( xml )
	xmlUnloadFile( xml )
	
	if ( restart ) then
		restartResource( getThisResource() );
	end
end );