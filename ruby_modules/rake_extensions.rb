


#-----------------------------------------------------------------------------------------------------------
def copy_if_new( source_path, target_path )
  if File.exist? target_path
    log TRM::red "file #{target_path} exists; skip copy from #{source_path}"
  else
    cp source_path, target_path, :verbose => true
    end#if
  end#def

#-----------------------------------------------------------------------------------------------------------
def gem_available?( gem_name )
  return Gem::Specification::find_all_by_name( gem_name ).any?
  end#def
