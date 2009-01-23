require 'rubygems'
#gem 'mojombo-grit'
gem 'bmizerany-sinatra', '>=0.9'

require 'sinatra/base'
require 'rdiscount'
require 'sass'
require 'metaid'
#require 'grit'

class Hash
  def symbolize_keys
    inject({}) do |options, (key, value)|
      options[(key.to_sym rescue key) || key] = value
      options
    end
  end
end

module Glug

  class PageNotFound < Sinatra::NotFound
    attr_reader :name
    
    def initialize(name)
      @name = name
    end
  end

  module Entry
    class << self
      attr_accessor :classes

      def included(other)
        self.classes ||= []
        self.classes << other unless self.classes.include? other
      end

      def all
        self.classes.map{ |klass| klass.all }.flatten!
      end
    end
  end

  class Resource
    class << self
      attr_accessor :repo
      
      def find(*args)
        raise PageNotFound.new(args) unless File.exist? locate(*args)
        
        self.new(File.read(locate(*args)))
      end
      
      def all
        Dir.glob("#{basedir}/**/*.*").map do |f|
          new(File.read(f))
        end
      end

      def set_basedir(dir)
        @basedir = dir
      end

      def basedir
        File.expand_path(File.join(Resource.repo, @basedir))
      end

      def page_attr_accessor(*syms)
        syms.each do |sym|
          define_method(sym) { attributes[sym] }
          define_method("#{sym}=") { |v| attributes[sym] = v }
        end
      end
    end

    attr_accessor :content

    def initialize(content = '')
      self.content = content
    end
  end

  class Page < Resource
    set_basedir 'pages'
    
    class << self
      attr_accessor :repo

      def recent(limit = 10)
        all.sort { |a, b| b.updated_at <=> a.updated_at }[0, limit]
      end

      private
      
      # Constructs the full path to the requested file from a
      # path provided to sinatra
      def locate(*args)
        # TODO this will be a security hole, since ../ will likely work
        File.expand_path(File.join(basedir, args[0] + '.md'))
      end
    end

    attr_accessor :attributes
    page_attr_accessor :title, :author, :created_at, :updated_at, :category, :tags

    def initialize(raw_content = '')
      super(raw_content)
      self.attributes = {}
      
      transform(raw_content)
    end
    
    # Read the YAML frontmatter
    # +base+ is the String path to the dir containing the file
    # +name+ is the String filename of the file
    #
    # Returns nothing
    def transform(raw_data)
      if self.content =~ /\A(---.*?)---(.*)/m
        self.attributes = YAML.load($1).symbolize_keys
        self.content = $2
      end
    end
    
    def content_html
      md = ::Markdown.new(self.content)

      md.to_html
    end
  end

  class Post < Page
    include Entry
    
    set_basedir 'posts'
    
    class << self
      def locate(*args)
        year, month, day, slug = args

        File.expand_path(File.join(basedir, year, month, day, slug + '.md'))
      end
    end
  end
  
  class Style < Resource
    set_basedir 'styles'
    
    class << self
      def locate(*args)
        File.expand_path(File.join(basedir, args[0] + '.sass'))
      end
    end
    
    def content_css
      engine = ::Sass::Engine.new(self.content)
      engine.render
    end
  end

  module Helpers
    def title
      title = 'brandon.dimcheff.com'
      case 
      when @page
        title << " $$ #{@page.title}"
      end
      
      title
    end

    def verbose_time(time)
      time.utc.strftime("%H:%M:%S on %B %d, %Y")
    end
    
    def stylesheet(style)
      # TODO make this relative to the mount point of the app
      "<link href='/stylesheets/#{style}.css' rel='stylesheet' type='text/css' />"
    end

    def sass(style)
      "<link href='/styles/#{style}.css' rel='stylesheet' type='text/css' />"
    end

    def javascript(js)
      "<script type='text/javascript' src='/javascripts/#{js}.js'></script>"
    end
  end

  class Application < Sinatra::Application
    include Helpers
    
    configure do
      set :views, lambda { File.join(repo, 'templates') }
      set :public, lambda { File.join(repo, 'public') }
    end
    
    def initialize
      super
      Resource.repo = self.class.repo
    end

    get '/' do
      @entries = Entry.all

      haml :index
    end

    get '/foo' do
      Sinatra.options.repo
    end

    get '/:page' do
      puts "repo in action: #{Resource.repo}"
      @page = Page.find(params[:page])
      
      haml :page
    end

    get %r!^/(\d{4})/(\d{2})/(\d{2})/(.*)$! do
      @page = Post.find(*params[:captures])
      
      haml :post
    end

    get '/styles/:style.css' do
      style = Style.find(params[:style])
      
      content_type 'text/css', :charset => 'utf-8'
      style.content_css
    end
  end
end

if __FILE__ == $0
  Glug::Application.set :repo, File.join(File.dirname(__FILE__), 'repo')
  Glug::Application.set :app_file, $0
  Glug::Application.set :server, 'mongrel'
  Glug::Application.run!
end
