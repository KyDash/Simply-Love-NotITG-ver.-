Detected = {}
setmetatable(_G,
    {
        __newindex = function ( self, key, val )
            print( "NEW GLOBAL - KEY:", key, "VALUE:", val )
            Detected[key] = val
            rawset( self, key, val )
        end
    }
)