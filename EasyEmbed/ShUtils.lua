local headerKey = "*#7qupUO5Fin0Mpu" 

function fileGetPrivateHeader( file )
	local headData	= fileRead( file, 128 )
	local endpos	= headData:find( "\n" )
	
	if ( endpos ) then
		headData	= headData:sub( 1, endpos - 1 )
		headData 	= split( headData, "," )
	else
		headData	= false
	end
	
	fileSetPos( file, 0 )
	
	return headData, endpos
end

function fileSetPrivate( path, key )
	local tick = getTickCount()
	local name = path:match( "^.+/(.+)$" )
	
	print( ("[DEBUG] Encryption of file %s has started."):format( name ) )
	
	local file = fileOpen( path, true )
	
	if ( not file ) then
		return;
	end
	
	local headData, headSize = fileGetPrivateHeader( file )
	
	if ( headData ) then
		local unpackedSize = tonumber( headData [ 1 ] )
		
		if ( unpackedSize ) then
			fileClose( file )
			
			return print( ("[DEBUG] File %s is already encrypted. Missing. / ms %d"):format( name, getTickCount() - tick ) )
		end
	end
	
	local size		= fileGetSize( file )
	local buffer, iv= encodeString( "aes128", fileRead( file, size ), { key = key } )
	
	fileClose( file )
	
	file = fileCreate( path )
	
	fileWrite( file, ("0x%x,%s\n"):format( size, teaEncode( iv, headerKey ) ), buffer )
	
	fileFlush( file )
	
	fileClose( file )
	
	print( ("[DEBUG] File %s was successfully encrypted. / %d ms."):format( name, getTickCount() - tick ) )
end

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
	
	local size, iv = tonumber( headData [ 1 ] ), teaDecode( headData [ 2 ], headerKey )
	
	fileSetPos( file, headSize )
	
	local buffer = decodeString( "aes128", fileRead( file, size ), { key = key, iv = iv } )
	
	fileClose( file )
	
	return buffer
end