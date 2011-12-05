#!/usr/bin/env ruby

require 'fileutils'

class ToastHaiku

  class Post
    def initialize(title)
      @title = title
      @date = Time.now.localtime
      @slug = slug_for(@title)
      @post_path = sprintf("_posts/%04d-%02d-%02d-%s.markdown", @date.year, @date.month, @date.day, @slug)
      @image_dir = sprintf("uploads/%04d/%02d", @date.year, @date.month)
      @image_path = "#{@image_dir}/#{@slug}.jpg"
    end

    def save_post
      template = <<TEMPLATE
---
layout: post
title: #{@title}
tags:
- interesting
---
Post body

![image](/#{@image_path})
TEMPLATE

      puts "creating #{@post_path}"
      File.open(@post_path, "w") do |f|
        f << template
      end
    end

    def save_image
      puts "creating #{@image_dir}"
      FileUtils.mkdir_p @image_dir
    end

    private
    def slug_for(title)
      value = title.gsub(/[^\x00-\x7F]/n, '').to_s
      value.gsub!(/[']+/, '')
      value.gsub!(/\W+/, ' ')
      value.strip!
      value.downcase!
      value.gsub!(' ', '-')
    end
  end

  def self.server
    system 'bundle exec jekyll --server'
  end

  def self.preview
    system 'bundle exec jekyll && open http://localhost:4000'
  end

  def self.commit
    system "git add . && git commit -am 'new post' && git push origin master"
  end

  def self.deploy
    system 'rsync -avz _site/ drtoast@drtoast.com:toasthaiku.net'
  end

  def self.usage(cmd)
    puts "ERROR: command not recognized: #{ARGV[0]}"
    puts "Available commands: server, post, preview, commit, deploy"
  end

end

case ARGV[0]
when 'server'
  ToastHaiku.server
when 'post'
  title = ARGV[1]
  p = ToastHaiku::Post.new(title)
  p.save_post
  p.save_image
when 'preview'
  ToastHaiku.preview
when 'commit'
  ToastHaiku.commit
when 'deploy'
  ToastHaiku.deploy
else
  ToastHaiku.usage(ARGV[0])
end

