
module TRM

  #---------------------------------------------------------------------------------------------------------
  def self.rpr( x )
    return x.inspect
    end#def

  #---------------------------------------------------------------------------------------------------------
  def self.log( *p )
    $stdout.write self.pen *p
    end#def

  #---------------------------------------------------------------------------------------------------------
  def self.echo( *p )
    $stderr.write self.pen *p
    end#def

  #---------------------------------------------------------------------------------------------------------
  def self.pen( *p )
    # ### Given any number of arguments, return a text representing the arguments as seen fit for output
    # commands like `log`, `echo`, and the colors. ###
    return ( self._pen *p ) + "\n"
    end#def

  #---------------------------------------------------------------------------------------------------------
  def self._pen( *p )
    return ( p.map { |x| if ( x.is_a? String ) then x else TRM::rpr x end } ).join ' '
    end#def


  #---------------------------------------------------------------------------------------------------------
  def self.green()
    return "\x1b[38;05;34m"
    end

  #---------------------------------------------------------------------------------------------------------
  def self.red()
    return "\x1b[38;05;124m"
    end
  end#module


#-----------------------------------------------------------------------------------------------------------
def log( *p )
  TRM::log *p
  end#def

#-----------------------------------------------------------------------------------------------------------
def echo( *p )
  TRM::echo *p
  end#def


=begin


@blink                    = "\x1b[5m"
@bold                     = "\x1b[1m"
@reverse                  = "\x1b[7m"
@underline                = "\x1b[4m"

#-----------------------------------------------------------------------------------------------------------
# Effects Off
#...........................................................................................................
@no_blink                 = "\x1b[25m"
@no_bold                  = "\x1b[22m"
@no_reverse               = "\x1b[27m"
@no_underline             = "\x1b[24m"
@reset                    = "\x1b[0m"

#-----------------------------------------------------------------------------------------------------------
# Colors
#...........................................................................................................
@colors =
  black:                    "\x1b[38;05;16m"
  blue:                     "\x1b[38;05;27m"
  green:                    "\x1b[38;05;34m"
  cyan:                     "\x1b[38;05;51m"
  sepia:                    "\x1b[38;05;52m"
  indigo:                   "\x1b[38;05;54m"
  steel:                    "\x1b[38;05;67m"
  brown:                    "\x1b[38;05;94m"
  olive:                    "\x1b[38;05;100m"
  lime:                     "\x1b[38;05;118m"
  red:                      "\x1b[38;05;124m"
  crimson:                  "\x1b[38;05;161m"
  plum:                     "\x1b[38;05;176m"
  pink:                     "\x1b[38;05;199m"
  orange:                   "\x1b[38;05;208m"
  gold:                     "\x1b[38;05;214m"
  tan:                      "\x1b[38;05;215m"
  yellow:                   "\x1b[38;05;226m"
  grey:                     "\x1b[38;05;240m"
  darkgrey:                 "\x1b[38;05;234m"
  white:                    "\x1b[38;05;255m"

  # experimental:
  # colors as defined by http://ethanschoonover.com/solarized
  BASE03:                   "\x1b[38;05;234m"
  BASE02:                   "\x1b[38;05;235m"
  BASE01:                   "\x1b[38;05;240m"
  BASE00:                   "\x1b[38;05;241m"
  BASE0:                    "\x1b[38;05;244m"
  BASE1:                    "\x1b[38;05;245m"
  BASE2:                    "\x1b[38;05;254m"
  BASE3:                    "\x1b[38;05;230m"
  YELLOW:                   "\x1b[38;05;136m"
  ORANGE:                   "\x1b[38;05;166m"
  RED:                      "\x1b[38;05;124m"
  MAGENTA:                  "\x1b[38;05;125m"
  VIOLET:                   "\x1b[38;05;61m"
  BLUE:                     "\x1b[38;05;33m"
  CYAN:                     "\x1b[38;05;37m"
  GREEN:                    "\x1b[38;05;64m"



#-----------------------------------------------------------------------------------------------------------
# Moves etc
#...........................................................................................................
@cr                       = "\x1b[1G"       # Carriage Return; move to first column
@clear_line_right         = "\x1b[0K"       # Clear to end   of line
@clear_line_left          = "\x1b[1K"       # Clear to start of line
@clear_line               = "\x1b[2K"       # Clear all line content
@clear_below              = "\x1b[0J"       # Clear to the bottom
@clear_above              = "\x1b[1J"       # Clear to the top (including current line)
@clear                    = "\x1b[2J"       # Clear entire screen

=end
