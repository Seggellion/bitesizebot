# Railpress

Railpress is a Ruby on Rails–based **content management framework** inspired by WordPress, designed to be **theme‑agnostic**, extensible, and suitable as a reusable foundation for multiple websites.

Railpress is intentionally structured as an *application‑as‑framework*: it is cloned or forked to create downstream projects (such as **railpressbot**) and evolved over time. It is **not yet distributed as a Rails Engine**, by design.

---

## Philosophy

Railpress aims to provide:

- A clean, stable CMS core
- A WordPress‑style admin interface
- A first‑class theme system
- Graceful handling of missing or partial themes
- Clear separation between framework code and project‑specific code

If you are familiar with how WordPress separates *core* and *themes*, Railpress follows a similar mental model within Rails.

---

## Table of Contents

- Installation
- Configuration
- Usage
- Twitch modules
- Themes
- Admin Interface
- Deployment
- Contributing
- License

---

## Installation

### Prerequisites

Ensure you have the following installed:

- Ruby 3.2.2
- Rails 8.0+
- PostgreSQL
- Node.js
- Yarn
- Redis (for ActiveJob)
- ImageMagick (recommended for Active Storage variants)

---

### Setup

Clone the repository:

```bash
git clone https://github.com/Seggellion/railpress.git
cd railpress
```

Install system dependencies:

```bash
sudo apt install nodejs npm yarn
sudo apt install postgresql postgresql-contrib libpq-dev
```

Install Ruby dependencies:

```bash
gem install bundler
bundle install
```

Set up the database:

```bash
rails db:create
rails db:migrate
```

Start PostgreSQL if it is not running:

```bash
service postgresql start
```

Install Active Storage tables (if not already present):

```bash
rails active_storage:install
rails db:migrate
```

Start the Rails server:

```bash
rails server
```

Visit the application at:

```
http://localhost:3000
```

---

## Configuration

### Themes

Railpress ships with a default theme named **Dusk**.

Themes live under:

```
app/themes/<ThemeName>
```

Each theme may define:

- Layouts
- Views
- Partials
- Assets
- Optional UI sections (header, footer, sidebar)

Themes are loaded dynamically via view path prepending. Missing sections do not crash the app and instead render helpful fallback notices during development.

---

### Tailwind CSS

Tailwind CSS is used for styling.

To rebuild Tailwind manually:

```bash
npx tailwindcss \
  -i ./app/assets/stylesheets/application.tailwind.css \
  -o ./app/assets/stylesheets/application.css \
  --watch
```

---

### Fonts and Branding

Fonts and colors are managed via theme‑level partials and `Setting` records.

Examples:

- `header-font`
- `body-font`
- `primary-color`
- `secondary-color`

Themes may choose to ignore or override these settings.

---

### Active Storage

Active Storage is supported out of the box.

For Google Cloud Storage, configure the following environment variables:

```
GOOGLE_APPLICATION_CREDENTIALS_JSON
GOOGLE_APPLICATION_CREDENTIALS
```

---

## Usage

### Admin Interface

The admin interface is available at:

```
/admin
```

It provides management for:

- Pages
- Posts
- Articles
- Services
- Events
- Categories
- Menus
- Media
- Settings
- Users

The admin UI is WordPress‑inspired and styled with Tailwind CSS.

---

### Pages and Templates

Pages support:

- Slugs
- Categories
- Published states
- Theme‑specific templates

Themes control how pages are rendered. The CMS core does not special‑case routes such as the homepage.

---

## Themes

Railpress is designed to be **theme‑first**.

- Themes control layout and presentation
- The core layout remains minimal and stable
- Themes may be partial or incomplete without crashing the app
- Missing theme sections render visible development warnings

This makes Railpress suitable for rapid prototyping and long‑term maintenance.

---

## Deployment

### General Deployment

Railpress can be deployed like any standard Rails application.

Typical steps:

```bash
RAILS_ENV=production rails assets:precompile
rails db:migrate
```

---

### Heroku Example

Create the app:

```bash
heroku create
```

Set environment variables:

```bash
heroku config:set RAILS_ENV=production
heroku config:set GOOGLE_APPLICATION_CREDENTIALS_JSON=<base64-encoded-json>
```

Deploy:

```bash
git push heroku main
heroku run rails db:migrate
```

---

## Creating a New Project from Railpress

Railpress is intended to be **cloned**, not mounted.

Example workflow:

```bash
git clone git@github.com:Seggellion/railpress.git railpressbot
cd railpressbot
rm -rf .git
git init
git add .
git commit -m "Initialize project from Railpress v0.1"
```

Optionally, add Railpress as an upstream remote for future cherry‑picks.

---

## Contributing

Contributions are welcome.

- Fork the repository
- Create a feature branch
- Submit a pull request with clear intent

Please keep framework‑level changes generic and avoid project‑specific assumptions.

---

## License

Railpress is released under the MIT License.

See the LICENSE file for details.
