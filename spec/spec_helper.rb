current = File.dirname(File.dirname(__FILE__))
$LOAD_PATH << "#{current}/lib"
require "#{current}/init"
require "#{current}/spec/setup_database"
