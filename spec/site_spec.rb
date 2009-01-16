require 'rubygems'
gem 'rspec'
require 'spec'

# this prevents sinatra from trying to parse rspec-related
# command-line options
ARGV.clear

require 'sinatra'
require 'sinatra/test/rspec'
require 'site'

Spec::Runner.configure do |config|
  config.mock_with :flexmock
end

describe 'Page' do
  describe '.find' do    
    it 'finds the page that is returned by locate' do
      flexmock(File, :exist? => true)
      flexmock(Page, :locate => 'foo')
      flexmock(File).should_receive(:read).with('foo').and_return('bar')
      
      page = Page.find('post')
    end

    it 'throws a PageNotFound exception if the file cannot be found' do
      flexmock(Page, :locate => 'foo')
      flexmock(File, :exist? => false)

      lambda { Page.find('post') }.should raise_error(PageNotFound)
    end
  end

  describe '.locate' do
    it 'returns files out of [repo]/pages' do
      flexmock(Page, 'repo.path' => '/path/to/repo/.git')

      Page.send(:locate, 'testpage').should == '/path/to/repo/pages/testpage'
    end
  end

  describe '#parse' do
    it 'parses plain text into content' do
      data = <<EOF
plain text test
EOF

      Page.new(data).content.strip.should == 'plain text test'
    end

    it 'parses yaml into attributes, the rest into content' do
      data = <<EOF
---
foo: bar
baz: [quux]
--- 
text content
EOF
      page = Page.new(data)
      
      page.content.strip.should == 'text content'
      page.attributes.size.should == 2
      page.attributes['foo'].should == 'bar'
      page.attributes['baz'].should == ['quux']
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

      page = Page.new(data)
      page.title.should == 'foo'
    end

    it 'returns nil if there is no title in the attributes' do
      data = <<EOF
---
foo: bar
---
content
EOF
      page = Page.new(data)
      page.title.should be_nil
    end
  end

  describe '.attr_method' do
    it 'should create the proper methods' do
      data = <<EOF
---
foo: bar
baz: quux
---
content
EOF
      
      klass = Class.new(Page) do
        post_attr_accessor :foo
      end

      page = klass.new(data)

      page.foo.should == 'bar'
    end
  end
end

describe 'Post' do
  describe '.locate' do
    it 'returns files out of [repo]/posts/YYYY/MM/DD/slug' do
      flexmock(Page, 'repo.path' => '/path/to/repo/.git')

      Post.send(:locate, '2008', '01', '01', 'testpost').should == '/path/to/repo/posts/2008/01/01/testpost'
    end
  end
end

def create_page(options = {})
  p = Page.new

 #p.
end
