# Coding Agent Guidelines

This file provides guidance to code agents when working with code in this repository.

## Project Overview

(... Your project overview here ...)

## Guidelines

- When running commands locally, avoid chaining them with && when possible.
- The repository is hosted on GitLab. A `.gitlab-ci.yml` file should be present
  and updated when necessary.
- The code should be tested.
- The code should pass the linter at all times.
- When using external libraries, the latest stable version should be used.
- Any code written should be well documented.
- The README should stay up to date.
- A `.gitignore` file should be present and up to date. If you commit changes and
  to not include some files in the commit, you should add them to the `.gitignore`.
- Any code written should follow the best practices in security.
- Dependency lock files (e.g., `package-lock.json`) should always be committed.
- Unnecessary refactorings should be avoided.
- If the task is a documentation-only task, do not implement any code.

### Testing

When writing tests, follow these specific guidelines:

- Do not try to test files that are not code.
- Make sure to write unit tests for any component, and higher-level tests when
  it makes sense.
- When trying to fix broken tests, always prefer to adapt the tests to the
  expected behavior rather than adapting the code to make the tests happy.
