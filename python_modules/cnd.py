
#-----------------------------------------------------------------------------------------------------------
import json as _JSON
no  = False
yes = True


#-----------------------------------------------------------------------------------------------------------
blink       = '\x1b[5m'
bold        = '\x1b[1m'
reverse     = '\x1b[7m'
underline   = '\x1b[4m'
reset       = '\x1b[0m'
black       = '\x1b[38;05;16m'
blue        = '\x1b[38;05;27m'
green       = '\x1b[38;05;34m'
cyan        = '\x1b[38;05;51m'
sepia       = '\x1b[38;05;52m'
indigo      = '\x1b[38;05;54m'
steel       = '\x1b[38;05;67m'
brown       = '\x1b[38;05;94m'
olive       = '\x1b[38;05;100m'
lime        = '\x1b[38;05;118m'
red         = '\x1b[38;05;124m'
crimson     = '\x1b[38;05;161m'
plum        = '\x1b[38;05;176m'
pink        = '\x1b[38;05;199m'
orange      = '\x1b[38;05;208m'
gold        = '\x1b[38;05;214m'
tan         = '\x1b[38;05;215m'
yellow      = '\x1b[38;05;226m'
grey        = '\x1b[38;05;240m'
darkgrey    = '\x1b[38;05;234m'
white       = '\x1b[38;05;255m'

#-----------------------------------------------------------------------------------------------------------
def debug( *P ):
  R = []
  for p in P:
    if isinstance( p, str ):  R.append( p )
    else:                     R.append( repr( p ) )
  R = ' '.join( R )
  print( pink + R + reset )

#-----------------------------------------------------------------------------------------------------------
rpr = repr

#-----------------------------------------------------------------------------------------------------------
def jr( *P ):
  if len( P ) == 1: return _JSON.dumps( P[ 0 ], ensure_ascii = no )
  return ' '.join( _JSON.dumps( p, ensure_ascii = no ) for p in P )




