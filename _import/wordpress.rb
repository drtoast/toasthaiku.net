require 'rubygems'
require 'sequel'
require 'fileutils'
require 'yaml'

# NOTE: This converter requires Sequel and the MySQL gems.
# The MySQL gem can be difficult to install on OS X. Once you have MySQL
# installed, running the following commands should work:
# $ sudo gem install sequel
# $ sudo gem install mysql -- --with-mysql-config=/usr/local/mysql/bin/mysql_config

module Jekyll
  module WordPress
    def self.process(dbname, user, pass, host = 'localhost', table_prefix = 'wp_')
      db = Sequel.mysql(dbname, :user => user, :password => pass, :host => host, :encoding => 'utf8')
      htaccess = File.open("htaccess", "w")
      

      # Reads a MySQL database via Sequel and creates a post file for each
      # post in wp_posts that has post_status = 'publish'. This restriction is
      # made because 'draft' posts are not guaranteed to have valid dates.
      query = <<SQL

SELECT p.post_title,
      p.post_name,
      p.post_date,
      p.post_content,
      p.post_excerpt,
      p.ID,
      p.guid,
      group_concat(t.slug) categories
FROM wp_posts p
LEFT JOIN wp_term_relationships tr
ON tr.object_id = p.ID
LEFT JOIN wp_term_taxonomy tt
ON tr.term_taxonomy_id = tt.term_taxonomy_id
LEFT JOIN wp_terms t
ON t.term_id = tt.term_id
WHERE p.post_status = 'publish' AND p.post_type = 'post'
GROUP BY p.ID

SQL


      db[query].each do |post|
        next if post[:categories].match(/haiku/)
        puts post[:categories]
        # Get required fields and construct Jekyll compatible name.
        title = post[:post_title]
        slug = post[:post_name]
        date = post[:post_date]
        content = post[:post_content]
        content.gsub!(%r(http://www.drtoast.com/wp-content/uploads/), '/uploads/')
        content.gsub!(%r(rating: <img src="/files/images/.*>), '')
        content.gsub!(/\r/, '<br />')
        name = "%02d-%02d-%02d-%s.html" % [date.year, date.month, date.day, slug]
        # Get the relevant fields as a hash, delete empty fields and convert
        # to YAML for the header.
        data = {
           'layout' => 'post',
           'title' => title.to_s,
           'excerpt' => post[:post_excerpt].to_s,
           'wordpress_id' => post[:ID],
           'date' => date,
           'tags' => post[:categories].split(/,/).uniq.reject{|a| ['elsewhere'].include?(a)}
         }.delete_if { |k,v| v.nil? || v == '' }
        # Write out the data and content to file
        category = data['tags'].last
        dir = "_posts"
        FileUtils.mkdir_p(dir) unless File.directory?(dir)
        File.open("#{dir}/#{name}", "w") do |f|
          f.puts data.to_yaml
          f.puts "---"
          f.puts content
        end
        # htaccess << "Redirect 301 %s http://toasthaiku.net/%02d/%02d/%02d/%s.html\n" % [wordpress_url, date.year, date.month, date.day, slug]
      end
    end
  end
end

Jekyll::WordPress.process("toasthaikuwp", "root", "", "127.0.0.1")
