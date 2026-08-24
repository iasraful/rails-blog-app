puts 'Creating users...'
User.destroy_all
Post.destroy_all

admin = User.create!(
  email_address: 'iasraful321@gmai.com',
  password: 'password',
  role: :admin
)

editor = User.create!(
  email_address: 'editor@example.com',
  password: 'password',
  role: :editor
)

user = User.create!(
  email_address: 'user@example.com',
  password: 'password',
  role: :user
)

puts 'Creating posts...'
5.times do |i|
  admin.posts.create!(
    title: \"Admin Premium Post #{i + 1}\",
    content: \"This is a beautiful post created by the administrator to demonstrate the new Tailwind UI. Enjoy the reading experience!\"
  )
end

3.times do |i|
  editor.posts.create!(
    title: \"Editor Insight #{i + 1}\",
    content: \"This post was published by our editor. It covers interesting topics about web development.\"
  )
end

puts 'Database seeded successfully!'
