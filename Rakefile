require 'jeweler'
require 'rake'
require 'rake/clean'
require 'rake/testtask'
require 'reek/rake/task'

BASEDIR = File.dirname(__FILE__)

$LOAD_PATH << File.join([BASEDIR, 'lib'])
$LOAD_PATH << BASEDIR

require 'bnchmrkr'

CLEAN.include('bnchmrkr.gemspec')
CLOBBER.include('pkg/*')

Jeweler::Tasks.new do |gem|
  gem.name        = 'bnchmrkr'
  gem.summary     = 'compare execution time'
  gem.description = 'given a hash of lambdas, runs and compares the amount of time each implementation takes'
  gem.email       = 'conor.code@gmail.com'
  gem.homepage    = 'http://github.com/chorankates/bnchmrkr'
  gem.authors     = ['Conor Horan-Kates']
  gem.licenses    =  'MIT'

  # these files are useful for repo users, but too bulky for gem
  gem.files.exclude 'resources/*'
  gem.files.exclude 'examples/*'

end
Jeweler::RubygemsDotOrgTasks.new

namespace :test do
  Rake::TestTask.new do |t|
    t.name = 'unit'
    t.libs << 'lib'
    t.test_files = FileList['test/unit/**/test_*.rb']
    t.verbose = true
  end

  Rake::TestTask.new do |t|
    t.name = 'examples'
    t.libs << 'lib'
    t.test_files = FileList['test/examples/**/*.rb']
    t.verbose = true
  end

end

desc 'run all tests'
task :test => ['test:unit', 'test:examples'] do
end

desc 'run all examples'
task :examples do
  Dir.glob('examples/*.rb').each do |file|
    sh "time ruby #{file}"
    puts
  end
end

Reek::Rake::Task.new do |t|
  t.config_file   = File.join(BASEDIR, '.reek')
  t.source_files  = './**/*.rb'
  t.reek_opts     = '-U'
  t.fail_on_error = false
  t.verbose       = true
end