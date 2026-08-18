code = File.read('/home/asraf/blog_app/app/views/posts/show.html.erb')
code.gsub!(/<%= link_to "Edit this post".*?%>\n/, '')
code.gsub!(/<%= link_to "Back to posts".*?%>\n/, '')
code.gsub!(/<%= button_to "Destroy this post".*?%>\n/, '')
code.sub!(/<\/div>\n<div class="max-w-3xl/, "</div>\n<%= link_to 'Back to posts', posts_path, class: 'mb-4 inline-block text-blue-600 hover:underline' %>\n<div class=\"max-w-3xl")
File.write('/home/asraf/blog_app/app/views/posts/show.html.erb', code)

File.write('/home/asraf/blog_app/db/migrate/20260818210500_add_role_to_users.rb', <<~RUBY)
class AddRoleToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :role, :integer, default: 0
  end
end
RUBY
