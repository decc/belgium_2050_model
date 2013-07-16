task :default => :generate_new_mode_from_excel

desc "Update all the code, based on the spreadsheet in spreadsheet/2050Model.xlsx"
task :generate_new_mode_from_excel => [:clean,'ext/belgium_2050_model.c',:put_generated_files_in_right_place,:fix_test_require, :change_last_modified_date]

desc "Generates c version of 2050 pathways model"
file 'ext/belgium_2050_model.c' do
  require 'excel_to_code'
  command = ExcelToC.new

  command.excel_file = "spreadsheet/2050Model.xlsx"
  command.output_directory = 'ext'
  command.output_name = 'belgium_2050_model'

  command.cells_that_can_be_set_at_runtime = { "CONTROL" => (4.upto(55).to_a.map { |r| "h#{r}" })+(4.upto(32).to_a.map { |r| "ab#{r}" })}

  command.cells_to_keep = {
    # The names, limits, 10 worders, long descriptions
    "CONTROL" => :all,
    "OUTPUT" => :all,
    "Costs" => :all, 
  }

  command.actually_compile_code = true
  command.actually_run_tests = true

  command.run_in_memory = true

  command.go!
end

# Put things in their place
task :put_generated_files_in_right_place do
  require 'ffi'
  libfile = FFI.map_library_name('belgium_2050_model')
  if File.exists?(File.join('ext',libfile))
    mv File.join('ext',libfile), File.join('lib','belgium_2050_model',libfile)
  end

  mv 'ext/belgium_2050_model.rb', 'lib/belgium_2050_model/belgium_2050_model.rb'
  mv 'ext/test_belgium_2050_model.rb', 'test/test_belgium_2050_model.rb'
  rm 'ext/Makefile'
end

task :fix_test_require do
  test = IO.readlines('test/test_belgium_2050_model.rb').join
  test.gsub!("require_relative 'belgium_2050_model'","require_relative '../lib/belgium_2050_model'")
  File.open('test/test_belgium_2050_model.rb','w') { |f| f.puts test }
end

desc "This updates the Belgium2050Model.last_modified_date attribute to the current time"
task :change_last_modified_date do
  File.open('lib/belgium_2050_model/belgium_2050_model_version.rb','w') do |f|
    f.puts "def Belgium2050Model.last_modified_date() @last_modified_date ||= Time.utc(*#{Time.now.to_a}); end"
  end
end

desc "Remove all the spreadsheet code, ready to be regenerated"
task :clean do
  rm 'lib/belgium_2050_model/belgium_2050_model.rb', :force => true
  rm 'test/test_belgium_2050_model.rb', :force => true
  rm 'ext/belgium_2050_model.c', :force => true
end
