User.create!(
  email: "admin@example.com",
  username: "admin",
  user_type: 0
)

Setting.create!(key: "current-theme", value: "Dusk")

Page.create!(
  title: "Home",
  slug: "home",
  published: true
)