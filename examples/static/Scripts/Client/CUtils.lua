function fileGetPrivateBuffer( path, key )
	local tick = getTickCount()
	local name = path:match( "^.+/(.+)$" )
	
	local file = fileOpen( path, true )
	
	if ( not file ) then
		return
	end
	
	local headData, headSize = fileGetPrivateHeader( file )
	
	if ( not headData ) then
		return
	end
	
	local size, iv = tonumber( headData [ 1 ] ), teaDecode( headData [ 2 ], "FxhnkW|IsqXBuNLT"  )
	
	fileSetPos( file, headSize )
	
	local buffer = decodeString( "aes128", fileRead( file, size ), { key = key, iv = iv } )
	
	fileClose( file )
	
	return buffer
end