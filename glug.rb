require 'rubygems'
gem 'mojombo-grit'
gem 'bmizerany-sinatra'

require 'sinatra/base'
require 'grit'


class PageNotFound < Sinatra::NotFound
  attr_reader :name
 
  def initialize(name)
    @name = name
  end
end

class Page
  class << self
    attr_accessor :repo
    
    def find(*args)
      raise PageNotFound.new(args) unless File.exist? locate(*args)
      
      self.new(File.read(locate(*args)))
    end

    private
    
    # Constructs the full path to the requested file from a
    # path provided to sinatra
    def locate(*args)
      # TODO this will be a security hole, since ../ will likely work
      File.expand_path(File.join(repo, 'pages', args[0] + '.md'))
    end

    def post_attr_accessor(*syms)
      syms.each do |sym|
        define_method(sym) { attributes[sym.to_s] }
        define_method("#{sym}=") { |v| attributes[sym.to_s] = v }
      end
    end
  end

  attr_accessor :attributes, :content
  post_attr_accessor :title, :author, :date, :category, :tags

  def initialize(raw_content = '')
    self.content = ''
    self.attributes = {}
    
    parse(raw_content)
  end
  
  # Read the YAML frontmatter
  # +base+ is the String path to the dir containing the file
  # +name+ is the String filename of the file
  #
  # Returns nothing
  def parse(raw_data)
    self.content = raw_data
    
    if self.content =~ /\A(---.*?)---(.*)/m
      self.attributes = YAML.load($1)
      self.content = $2
    end
  end
  
  def save
    
  end
end

class Post < Page
  class << self
    def locate(*args)
      year, month, day, slug = args

      File.expand_path(File.join(Page.repo.path, '..', 'posts', year, month, day, slug))
    end
  end
end

class Glug < Sinatra::Base 
  configure do
    repo = File.expand_path(File.join(File.dirname(__FILE__), 'repo'))
    
    begin
      Page.repo = Grit::Repo.new(repo)
    rescue Grit::InvalidGitRepositoryError, Grit::NoSuchPathError
      abort "#{repo}: Not a git repository. Install your wiki with `rake bootstrap`"
    end
    
    set :views, File.join(repo, 'templates')  
  end

  get '/' do
    haml :index
  end

  get '/foo' do
    Sinatra.options.repo
  end

  get '/p/:page' do
    @page = Page.find(params[:page])
    
    haml :page
  end

  get %r!^/b/(\d{4})/(\d{2})/(\d{2})/(.*)$! do
    @page = Post.find(*params[:captures])
    
    haml :post
  end
end

if __FILE__ == $0
  Glug.run!
end
