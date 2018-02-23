
module TRM


  #=========================================================================================================
  # OUTPUT METHODS
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


  #=========================================================================================================
  # COLORS
  #---------------------------------------------------------------------------------------------------------
  def self._colorize ( color_code, *p )
    r         = [ color_code, ]
    last_idx  = p.length - 1
    p.each_with_index do | x, idx |
      if ( x.is_a? String ) then r.push x else r.push self.rpr x end
      if idx != last_idx
        r.push color_code
        r.push ' '
        end#if
      end#do
    r.push "\x1b[0m" # @constants[ 'reset' ]
    return r.join ''
    end#def

  #-----------------------------------------------------------------------------------------------------------
  # Colors
  #...........................................................................................................
  def self.black(     *p ) self._colorize "\x1b[38;05;16m",   *p; end
  def self.blue(      *p ) self._colorize "\x1b[38;05;27m",   *p; end
  def self.green(     *p ) self._colorize "\x1b[38;05;34m",   *p; end
  def self.cyan(      *p ) self._colorize "\x1b[38;05;51m",   *p; end
  def self.sepia(     *p ) self._colorize "\x1b[38;05;52m",   *p; end
  def self.indigo(    *p ) self._colorize "\x1b[38;05;54m",   *p; end
  def self.steel(     *p ) self._colorize "\x1b[38;05;67m",   *p; end
  def self.brown(     *p ) self._colorize "\x1b[38;05;94m",   *p; end
  def self.olive(     *p ) self._colorize "\x1b[38;05;100m",  *p; end
  def self.lime(      *p ) self._colorize "\x1b[38;05;118m",  *p; end
  def self.red(       *p ) self._colorize "\x1b[38;05;124m",  *p; end
  def self.crimson(   *p ) self._colorize "\x1b[38;05;161m",  *p; end
  def self.plum(      *p ) self._colorize "\x1b[38;05;176m",  *p; end
  def self.pink(      *p ) self._colorize "\x1b[38;05;199m",  *p; end
  def self.orange(    *p ) self._colorize "\x1b[38;05;208m",  *p; end
  def self.gold(      *p ) self._colorize "\x1b[38;05;214m",  *p; end
  def self.tan(       *p ) self._colorize "\x1b[38;05;215m",  *p; end
  def self.yellow(    *p ) self._colorize "\x1b[38;05;226m",  *p; end
  def self.grey(      *p ) self._colorize "\x1b[38;05;240m",  *p; end
  def self.darkgrey(  *p ) self._colorize "\x1b[38;05;234m",  *p; end
  def self.white(     *p ) self._colorize "\x1b[38;05;255m",  *p; end

  #---------------------------------------------------------------------------------------------------------
  end#module
  #---------------------------------------------------------------------------------------------------------

#-----------------------------------------------------------------------------------------------------------
def rpr(  *p ) TRM::rpr   *p; end
def log(  *p ) TRM::log   *p; end
def echo( *p ) TRM::echo  *p; end


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
