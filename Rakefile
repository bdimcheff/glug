require 'rubygems'
require 'git'
require 'spec'
require 'spec/rake/spectask'

desc "Create the git repository to store your site's content"
task :bootstrap do
  path = ENV['GIT_WIKI_REPO'] || File.expand_path(File.join(File.dirname(__FILE__), 'repo'))
  unless (Git.open(path) rescue false)
    repository = Git.init(path)
    puts "* Initialized the repository in #{path}"
  end
end

desc "Run the specs under spec"
Spec::Rake::SpecTask.new do |t|
  t.spec_opts = ['--options', "spec/spec.opts"]
  t.spec_files = FileList['spec/**/*_spec.rb']
end
