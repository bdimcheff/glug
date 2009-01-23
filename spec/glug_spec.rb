require 'rubygems'
gem 'rspec'
require 'spec'

# this prevents sinatra from trying to parse rspec-related
# command-line options
ARGV.clear

require 'sinatra/test/rspec'
require 'glug'

Spec::Runner.configure do |config|
  config.mock_with :flexmock
end

describe 'Glug::Page' do
  describe '.find' do    
    it 'finds the page that is returned by locate' do
      flexmock(File, :exist? => true)
      flexmock(Glug::Page, :locate => 'foo')
      flexmock(File).should_receive(:read).with('foo').and_return('bar')
      
      page = Glug::Page.find('post')
    end

    it 'throws a Glug::PageNotFound exception if the file cannot be found' do
      flexmock(Glug::Page, :locate => 'foo')
      flexmock(File, :exist? => false)

      lambda { Glug::Page.find('post') }.should raise_error(Glug::PageNotFound)
    end
  end

  describe '.locate' do
    it 'returns files out of [repo]/pages' do
      flexmock(Glug::Page, :basedir => '/path/to/repo/pages')

      Glug::Page.send(:locate, 'testpage').should == '/path/to/repo/pages/testpage.md'
    end
  end

  describe '.all' do
    it 'returns all files in [repo]/pages' do
      temp do |temp|
        ['foo', 'bar', 'baz'].each do |f|
          system("touch #{File.join(temp, 'pages', f)}.md")
        end

        flexmock(Glug::Page, :basedir => temp)

        Glug::Page.all.should have(3).pages
      end
    end
  end

  describe '#transform' do
    it 'parses plain text into content' do
      data = <<EOF
plain text test
EOF

      Glug::Page.new(data).content.strip.should == 'plain text test'
    end

    it 'parses yaml into attributes, the rest into content' do
      data = <<EOF
---
foo: bar
baz: [quux]
--- 
text content
EOF
      page = Glug::Page.new(data)
      
      page.content.strip.should == 'text content'
      page.attributes.size.should == 2
      page.attributes[:foo].should == 'bar'
      page.attributes[:baz].should == ['quux']
    end
  end

  describe '#title' do
    it 'loads the title from the attributes' do
      data = <<EOF
---
title: foo
---
content
EOF

      page = Glug::Page.new(data)
      page.title.should == 'foo'
    end

    it 'returns nil if there is no title in the attributes' do
      data = <<EOF
---
foo: bar
---
content
EOF
      page = Glug::Page.new(data)
      page.title.should be_nil
    end
  end

  describe '.page_attr_accessor' do
    it 'should create the proper methods' do
      data = <<EOF
---
foo: bar
baz: quux
---
content
EOF
      
      klass = Class.new(Glug::Page) do
        page_attr_accessor :foo
      end

      page = klass.new(data)

      page.foo.should == 'bar'
    end
  end

  describe '#content_html' do
    it 'should convert markdown into html' do
      Glug::Page.new('# h1').content_html.strip.should == '<h1>h1</h1>'
    end
  end
  
  describe '#created_at' do
    
  end

  describe '#updated_at' do
    
  end
end

describe 'Glug::Post' do
  describe '.locate' do
    it 'returns files out of [repo]/posts/YYYY/MM/DD/slug' do
      flexmock(Glug::Post, :basedir => '/path/to/repo/posts')

      Glug::Post.send(:locate, '2008', '01', '01', 'testpost').should == '/path/to/repo/posts/2008/01/01/testpost.md'
    end
  end
end

def create_page(options = {})
  p = Glug::Page.new

 #p.
end

def temp(&block)
  temp = File.expand_path(File.join(File.dirname(__FILE__), 'tmp'))
  FileUtils.rm_r(temp) if File.exist? temp
  
  FileUtils.mkdir_p(File.join(temp, 'pages'))
  
  yield temp

  FileUtils.rm_r(temp)
end
