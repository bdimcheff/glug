require 'rubygems'
#gem 'mojombo-grit'
gem 'bmizerany-sinatra', '>=0.8.9'

require 'sinatra/base'
require 'rdiscount'
require 'sass'
#require 'grit'

module Glug

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

      def all
        Dir.glob("#{basedir}/**/*.*").map do |f|
          new(File.read(f))
        end
      end

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

      def basedir
        File.expand_path(File.join(repo, 'pages'))
      end

      def page_attr_accessor(*syms)
        syms.each do |sym|
          define_method(sym) { attributes[sym.to_s] }
          define_method("#{sym}=") { |v| attributes[sym.to_s] = v }
        end
      end
    end

    attr_accessor :attributes, :content
    page_attr_accessor :title, :author, :created_at, :updated_at, :category, :tags

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
    
    def content_html
      md = ::Markdown.new(self.content)

      md.to_html
    end
    
    def save
      
    end
  end

  class Post < Page
    class << self
      def locate(*args)
        year, month, day, slug = args

        File.expand_path(File.join(basedir, year, month, day, slug + '.md'))
      end

      def basedir(*args)
        File.expand_path(File.join(Page.repo, 'posts'))
      end
    end
  end
  
  #TODO refactor some page functionality into a Resource so we don't
  #get a bunch of extra crap in style that isn't necessary
  class Style < Page
    class << self
      def locate(*args)
        File.expand_path(File.join(Page.repo, 'styles', args[0] + '.sass'))
      end
    end
    
    def content_css
      engine = ::Sass::Engine.new(self.content)
      engine.render
    end
  end

  class Application < Sinatra::Application

    
    configure do
      set :views, lambda { File.join(repo, 'templates') }
      set :public, lambda { File.join(repo, 'public') }
    end

    def stylesheet(style = 'main')
      # TODO make this relative to the mount point of the app
      "/styles/#{style}.css"
    end
    
    def initialize
      super
      Page.repo = self.class.repo
    end
    
    get '/' do
      @page = Page.find('index')
      
      haml :page
    end

    get '/foo' do
      Sinatra.options.repo
    end

    get '/:page' do
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
  Glug::Application.run!
end
