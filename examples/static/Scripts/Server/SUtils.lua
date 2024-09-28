function fileSetPrivate( path, key )
	local tick = getTickCount()
	local name = path:match( "^.+/(.+)$" )
	local file = fileOpen( path, true )
	
	if ( not file ) then
		return;
	end
	
	local headData, headSize = fileGetPrivateHeader( file )
	
	if ( headData ) then
		local unpackedSize = tonumber( headData [ 1 ] )
		
		if ( unpackedSize ) then
			fileClose( file )
			
			return;
		end
	end
	
	local size		= fileGetSize( file )
	local buffer, iv= encodeString( "aes128", fileRead( file, size ), { key = key } )
	
	fileClose( file )
	
	file = fileCreate( path .. "rw" )
	
	fileWrite( file, ("0x%x,%s\n"):format( size, teaEncode( iv, "FxhnkW|IsqXBuNLT" ) ), buffer )
	
	fileFlush( file )
	
	fileClose( file )
	
	print( ("[DEBUG] File %s was successfully encrypted. / %d ms."):format( name, getTickCount() - tick ) )
end