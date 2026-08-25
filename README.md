# Blog App

> A full-featured blog platform built with **Ruby on Rails 8.1**, featuring user registration, session-based authentication, role-based authorization via **CanCanCan**, and flash messaging for a smooth user experience.

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Tech Stack](#tech-stack)
3. [Getting Started](#getting-started)
4. [Database Setup & Seed Data](#database-setup--seed-data)
5. [Authentication — How Login Works](#authentication--how-login-works)
6. [User Registration & Form Validation](#user-registration--form-validation)
7. [Authorization with CanCanCan](#authorization-with-cancancan)
8. [Roles & Permissions](#roles--permissions)
9. [Flash Messages & Error Handling](#flash-messages--error-handling)
10. [Navigation Bar](#navigation-bar)
11. [Running the Test Suite](#running-the-test-suite)
12. [Demo Credentials](#demo-credentials)
13. [CI/CD Pipeline](#cicd-pipeline)
14. [License](#license)

---

## Project Overview

The **Blog App** is a multi-user blogging platform where:

- **Visitors** can browse and read all posts and comments without signing in.
- **Registered users** can sign up with an email and password, create posts, and leave comments.
- **Editors** have extended privileges to manage all posts and moderate comments.
- **Admins** have full control over every resource on the site.

The app demonstrates several important Rails concepts:

- Session-based authentication (built-in Rails 8 Authentication concern)
- Role-based access control using **CanCanCan**
- Custom flash alert messages when unauthorized actions are attempted
- Model-level validations for data integrity
- A global navigation bar that adapts based on authentication state

---

## Tech Stack

| Technology | Purpose |
|---|---|
| Ruby 3.2.3 | Programming language |
| Rails 8.1.3.1 | Web framework |
| SQLite 3 | Development database |
| CanCanCan 3.6.1 | Role-based authorization |
| bcrypt | Password hashing (has_secure_password) |
| Turbo (Hotwire) | Fast navigation without full page reloads |
| Tailwind CSS v4 | Utility-first styling |
| GitHub Actions | CI/CD (Brakeman, RuboCop, tests) |

---

## Getting Started



Open your browser at **http://localhost:3000**.

---

## Database Setup & Seed Data

Running in/rails db:setup (or db:seed) will create demo users for each role:

| Role | Email | Password |
|------|-------|----------|
| Admin | iasraful321@gmai.com | password |
| Editor | editor@example.com | password |
| Regular User | user@example.com | password |

> These credentials are for development/demo only. Change them before deploying to production.

---

## Authentication — How Login Works

Authentication is handled by the **Rails 8 built-in Authentication concern** (pp/controllers/concerns/authentication.rb), which provides:

- uthenticated? — returns 	rue if a user session exists.
- current_user — returns the currently logged-in User record (exposed as a helper method to views).
- Automatic redirection to the sign-in page for pages that require authentication.

The session lifecycle is managed in SessionsController:
- POST /session — validates credentials, starts a new session.
- DELETE /session — destroys the current session (sign out).

Passwords are stored securely using **bcrypt** via Rails' has_secure_password. Plain-text passwords are never stored.

---

## User Registration & Form Validation

New users can register at /users/new (the **Sign Up** page).

### How it works

1. The visitor fills in their **email address**, **password**, and **password confirmation**.
2. On submit, UsersController#create attempts to save a new User.
3. If validation passes, the user is automatically logged in and redirected to the home page.
4. If validation fails, the form re-renders with clear inline error messages.

### Validations (pp/models/user.rb)



| Rule | Detail |
|---|---|
| Email required | Cannot be blank |
| Email unique | No duplicate accounts |
| Email format | Must be a valid email (e.g. you@example.com) |
| Password required | Cannot be blank |
| Password minimum length | At least 6 characters |

Email addresses are automatically normalized (stripped and downcased) before saving, so User@Example.COM and user@example.com are treated as the same address.

---

## Authorization with CanCanCan

**CanCanCan** is a Ruby gem that provides a clean way to define what each user is allowed to do. All permissions are declared in a single file: pp/models/ability.rb.

### How it integrates

1. **load_and_authorize_resource** is declared in controllers (e.g. PostsController). This automatically:
   - Loads the resource (@post, @comment, etc.) from the database.
   - Checks if the current user is permitted to perform the action.

2. If the user **does not** have permission, CanCanCan raises a CanCan::AccessDenied exception.

3. This exception is **caught globally** in ApplicationController:



The result: instead of showing a raw error page, the user is **redirected back** to wherever they came from, and a **red alert banner** appears at the top of the page with the message:

> ⚠️ _You are not authorized to perform this action._

### Ability definitions (pp/models/ability.rb)



---

## Roles & Permissions

The User model uses a Rails **enum** for the role:



| Action | Admin | Editor | User (own content) | Visitor |
|--------|:-----:|:------:|:------------------:|:-------:|
| Read posts & comments | ✅ | ✅ | ✅ | ✅ |
| Create a post | ✅ | ✅ | ✅ | ❌ |
| Create a comment | ✅ | ✅ | ✅ | ❌ |
| Edit **any** post | ✅ | ✅ | ❌ | ❌ |
| Edit **own** post | ✅ | ✅ | ✅ | ❌ |
| Delete **any** post | ✅ | ❌ | ❌ | ❌ |
| Delete **own** post | ✅ | ❌ | ✅ | ❌ |
| Edit **any** comment | ✅ | ❌ | ❌ | ❌ |
| Edit **own** comment | ✅ | ❌ | ✅ | ❌ |
| Delete **any** comment | ✅ | ✅ | ❌ | ❌ |
| Delete **own** comment | ✅ | ✅ | ✅ | ❌ |
| Manage users | ✅ | ❌ | ❌ | ❌ |

### What happens when a user tries an unauthorized action?

For example, if a **regular user** clicks the **Destroy** button on someone else's post:

1. The browser sends a DELETE /posts/:id request.
2. PostsController calls load_and_authorize_resource.
3. CanCanCan checks bility.rb — the user does not own that post, so the ability is denied.
4. CanCan::AccessDenied is raised.
5. ApplicationController catches it and redirects the user back, showing:

   > **You
