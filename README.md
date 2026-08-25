# Blog App

A multi-user blogging platform built with **Ruby on Rails 8.1** and **PostgreSQL**. Users can register, write posts, leave comments, and manage content based on their assigned role (Admin, Editor, or Regular User).

---

## Tech Stack

| Technology | Purpose |
|---|---|
| Ruby 3.2.3 | Programming language |
| Rails 8.1.3.1 | Web framework (MVC architecture) |
| **PostgreSQL** | Database (via `pg` gem in Gemfile, `adapter: postgresql` in database.yml) |
| CanCanCan 3.6.1 | Role-based authorization |
| bcrypt | Password hashing (`has_secure_password`) |
| Turbo / Hotwire | SPA-like navigation without full page reloads |
| Tailwind CSS v4 | Utility-first CSS framework |
| GitHub Actions | CI/CD pipeline (Brakeman, RuboCop, Tests) |

---

## Getting Started

```bash
git clone <repo-url>
cd blog_app
bundle install
bin/rails db:setup    # PostgreSQL must be running
bin/rails server      # Visit http://localhost:3000
```

---

## How the Code Works (Detailed)

### 1. Authentication — How Login Works

Rails 8 generates an **Authentication concern** (`app/controllers/concerns/authentication.rb`). Every controller inherits from `ApplicationController`, which includes this concern.

**Key methods provided by Authentication:**
- `authenticated?` — checks if a user has a valid session cookie
- `current_user` (defined in `ApplicationController`) — returns `Current.user`, the logged-in user object
- `start_new_session_for(user)` — creates a `Session` record in the DB and sets a signed cookie in the browser
- `terminate_session` — deletes the session record and clears the cookie

**Login flow (`SessionsController`):**
```
User submits email + password
  -> SessionsController#create
  -> User.authenticate_by(email, password)
     (bcrypt compares the hash in password_digest column)
  -> If valid: start_new_session_for(user) -> redirect to home
  -> If invalid: redirect back with alert "Try another email..."
```

**Rate limiting** is applied to login: max 10 attempts in 3 minutes to prevent brute-force attacks:
```ruby
rate_limit to: 10, within: 3.minutes, only: :create
```

---

### 2. User Registration — How Sign Up Works

File: `app/controllers/users_controller.rb`

```
Visitor goes to /users/new (Sign Up page)
  -> UsersController#new renders the form
  -> Visitor fills in: email, password, password_confirmation
  -> Form submits POST /users
  -> UsersController#create:
     1. Builds User.new(email, password, password_confirmation)
     2. Forces role = :user (SECURITY: prevents role tampering)
     3. Calls @user.save
        -> If validations pass: auto-login + redirect to home
        -> If validations fail: re-render form with error messages
```

**Why `@user.role = :user` is important:** Even if someone tampers with the HTML form and adds a `role=admin` field, this line overrides it. New sign-ups are always regular users.

---

### 3. User Model — Validations & Password Hashing

File: `app/models/user.rb`

```ruby
has_secure_password  # bcrypt: hashes password -> stores in password_digest column
```

`has_secure_password` does 3 things:
1. Adds `password=` setter that **hashes** the password using bcrypt before saving
2. Adds `password_confirmation` attribute for form matching
3. Adds `authenticate(password)` method to verify passwords against the hash

**Validations (run before every save):**

| Validation | What it checks |
|---|---|
| `presence: true` (email) | Email cannot be blank |
| `uniqueness: { case_sensitive: false }` | No duplicate emails (case-insensitive) |
| `format: { with: URI::MailTo::EMAIL_REGEXP }` | Must be a valid email format |
| `presence: true` (password) | Password cannot be blank |
| `length: { minimum: 6 }` | Password must be at least 6 characters |
| `on: :create` | Password validation only runs for NEW users (not on profile updates) |

**Email normalization:**
```ruby
normalizes :email_address, with: ->(e) { e.strip.downcase }
```
This automatically converts `"  User@EXAMPLE.COM  "` to `"user@example.com"` before saving.

**Role enum:**
```ruby
enum :role, { user: 0, editor: 1, admin: 2 }
```
Stores an integer in the database (0, 1, or 2) but gives us human-readable methods like `user.admin?`, `user.editor?`, `user.role # => "admin"`.

---

### 4. Authorization with CanCanCan — Who Can Do What

File: `app/models/ability.rb`

**CanCanCan** is an authorization gem. Authentication answers "who are you?", while **authorization** answers "what are you allowed to do?"

**How it works step by step:**

1. In `PostsController`, we add: `load_and_authorize_resource`
2. Before every controller action, CanCanCan calls `Ability.new(current_user)`
3. It checks the `can` rules defined in `ability.rb`
4. If the user is allowed -> action proceeds normally
5. If the user is NOT allowed -> `CanCan::AccessDenied` exception is raised
6. `ApplicationController` catches this exception globally:

```ruby
rescue_from CanCan::AccessDenied do |_exception|
  respond_to do |format|
    format.html do
      redirect_back_or_to root_path,
        alert: "You are not authorized to perform this action.",
        status: :see_other
    end
    format.json do
      render json: { error: "..." }, status: :forbidden
    end
  end
end
```

**Result:** Instead of a crash or ugly error page, the user sees a **red alert banner** saying "You are not authorized to perform this action." and is redirected back.

---

### 5. Roles & Permission Matrix

Defined in `app/models/ability.rb`:

```ruby
if user.admin?
  can :manage, :all     # Everything on every model

elsif user.editor?
  can :read, :all
  can :create, [Post, Comment]
  can :update, Post     # Can edit ANY post
  can :destroy, Comment # Can delete ANY comment

else # Regular User
  can :read, :all
  can :create, [Post, Comment]
  can [:update, :destroy], Post, user_id: user.id    # Only OWN posts
  can [:update, :destroy], Comment, user_id: user.id  # Only OWN comments
end
```

**Permission Table:**

| Action | Admin | Editor | Regular User | Guest (not logged in) |
|--------|:-----:|:------:|:------------:|:-----:|
| Read posts & comments | ✅ | ✅ | ✅ | ✅ |
| Create new post | ✅ | ✅ | ✅ | ❌ |
| Create new comment | ✅ | ✅ | ✅ | ❌ |
| Edit ANY post | ✅ | ✅ | ❌ | ❌ |
| Edit OWN post | ✅ | ✅ | ✅ | ❌ |
| Delete ANY post | ✅ | ❌ | ❌ | ❌ |
| Delete OWN post | ✅ | ❌ | ✅ | ❌ |
| Delete ANY comment | ✅ | ✅ | ❌ | ❌ |
| Delete OWN comment | ✅ | ✅ | ✅ | ❌ |

**The `user_id: user.id` condition** is key: CanCanCan loads the resource from the database, then checks `resource.user_id == current_user.id`. If it doesn't match, the action is denied.

---

### 6. What Happens When an Unauthorized User Tries to Delete

Example: A **regular user** clicks "Destroy" on someone else's post.

```
1. Browser sends: DELETE /posts/5
2. PostsController has `load_and_authorize_resource`
3. CanCanCan loads Post.find(5) and calls Ability.new(current_user)
4. Checks: can?(:destroy, @post)
   -> ability.rb rule: can [:destroy], Post, user_id: user.id
   -> @post.user_id = 3, but current_user.id = 7
   -> MISMATCH -> Permission DENIED
5. CanCan::AccessDenied exception is raised
6. ApplicationController's rescue_from catches it
7. User is redirected back with a RED alert:
   "You are not authorized to perform this action."
```

No crash. No ugly 500 page. Just a clean, friendly message.

---

### 7. Flash Messages — Notice & Alert

File: `app/views/layouts/application.html.erb`

```erb
<% if notice.present? %>
  <div class="bg-green-50 text-green-800 ..."><%= notice %></div>
<% end %>

<% if alert.present? %>
  <div class="bg-red-50 text-red-800 ..."><%= alert %></div>
<% end %>
```

**How `notice` and `alert` work:**
- `notice` and `alert` are **flash messages** — temporary data stored in the session.
- When a controller does `redirect_to @post, notice: "Post created!"`, Rails stores "Post created!" in `flash[:notice]`.
- On the NEXT request (the redirect), the layout template checks `if notice.present?` and displays it.
- After that one request, the flash is automatically cleared.

| Type | Color | When it appears |
|------|-------|----------------|
| `notice` | Green | Success actions (post created, logged in, signed up) |
| `alert` | Red | Errors (unauthorized action, wrong password, rate limited) |

---

### 8. Strong Parameters — Preventing Mass Assignment

In every controller, form data goes through a whitelist method:

```ruby
# PostsController
def post_params
  params.expect(post: [ :title, :content ])
end

# UsersController
def user_params
  params.expect(user: [ :email_address, :password, :password_confirmation ])
end
```

**Why this matters:** Without strong parameters, a malicious user could add hidden fields to the form (e.g., `role=admin`) and change data they shouldn't. Strong parameters ensure ONLY the whitelisted fields are accepted.

---

### 9. Navigation Bar — Authentication-Aware UI

The layout (`application.html.erb`) changes based on login state:

**Not logged in:**
```
BlogApp                      [Sign In]  [Sign Up]
```

**Logged in as regular user:**
```
BlogApp    user@example.com  [user]  [Sign Out]
```

**Logged in as admin:**
```
BlogApp    admin@example.com  [admin]  [Sign Out]
```

The role badge (user/editor/admin) is always visible next to the email.

---

## Database Configuration

File: `config/database.yml`

```yaml
default: &default
  adapter: postgresql     # <-- This confirms PostgreSQL, NOT SQLite
  encoding: unicode
  username: postgres
  password: asdf          # Development only
  host: localhost

development:
  <<: *default
  database: blog_app_development

test:
  <<: *default
  database: blog_app_test
```

The `pg` gem in `Gemfile` is the PostgreSQL adapter:
```ruby
gem "pg", "~> 1.1"
```

---

## Running Tests

```bash
bin/rails test          # Run all tests (29 tests, 0 failures)
bin/rubocop -A          # Auto-fix Ruby style issues
bin/brakeman --no-pager # Security vulnerability scan
bin/bundler-audit       # Check gem vulnerabilities
```

## CI/CD Pipeline

GitHub Actions (`.github/workflows/ci.yml`) runs automatically on every push:
1. **Brakeman** — Static security analysis
2. **RuboCop** — Code style linting
3. **bundler-audit** — Gem vulnerability check
4. **importmap audit** — JS package vulnerability check
5. **Rails test suite** — All minitest tests

---

## Demo Credentials

| Role | Email | Password |
|------|-------|----------|
| **Admin** | `iasraful321@gmai.com` | `password` |
| **Editor** | `editor@example.com` | `password` |
| **Regular User** | `user@example.com` | `password` |

> These credentials are for development/demo only. Do not use in production.

---

## Key Files Reference

| File | Purpose |
|---|---|
| `app/models/user.rb` | User model — password hashing, roles, validations |
| `app/models/ability.rb` | CanCanCan permissions — all authorization rules |
| `app/controllers/application_controller.rb` | Global rescue for AccessDenied |
| `app/controllers/posts_controller.rb` | CRUD for blog posts |
| `app/controllers/users_controller.rb` | User registration (sign up) |
| `app/controllers/sessions_controller.rb` | Login and logout |
| `app/views/layouts/application.html.erb` | Global layout, nav bar, flash messages |
| `config/database.yml` | PostgreSQL connection config |
| `Gemfile` | All gem dependencies |

---

## License

This project is released under the [MIT License](https://opensource.org/licenses/MIT).
