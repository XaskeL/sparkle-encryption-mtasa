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