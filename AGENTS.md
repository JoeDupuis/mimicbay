# Project


# Stack
This is a rails project using the default stack:
- sqlite,
- solid queue/cable/cache
- hotwired (stimulus, turbo)
- Vanilla css

# Commands
- Run linter with `bundle exec rubocop -A`
- Run test with `bin/rails t`
- Run security static analysis with `bin/brakeman --no-pager`


# Git
- Never put yourself as co-author.

# Worktrees
- A `/worktrees` directory exists for agent-specific worktrees. Only the `.keep`
  file is tracked; everything else is ignored so agents can work in parallel.

# Github
- On all PRs, if you aree claude add the claude label, if you are codex, add the codex label.
- Always make sure it passes tests, linter and static analysis before considering the task done or submitting a PR. Run them in parallel.

# Controllers and routes
- Avoid adding custom routes or actions. Prefer creating new controllers when you need additional behaviour.
- Stick to the default RESTful actions: `new`, `create`, `index`, `show`, `edit`, `update`, `destroy`.
- Avoid notice and alert copy in controller. use failure_message and success_message in NoticeI18n. Do not use the failure_message when rendering a failure to save a model since the form will show the validation error anyway.

# Views
- Use the `form_errors` helper instead of rendering the validation errors manually.
- To set a button with a custom method you need to use turbo_confirm not confirm.

# Ruby
- Prefer zeitwerk over using require and prefer putting require at the top of the file instead of in a method.

# Comments
- Do not put comments unless asked.
