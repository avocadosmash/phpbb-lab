# GitHub Copilot Instructions for phpBB

This document provides guidance for GitHub Copilot when working on the phpBB project.

## Project Overview

phpBB is a free, open-source bulletin board forum software written in PHP. This is a development repository for contributing to the phpBB core.

## Technology Stack

- **Backend**: PHP 8.1+
- **Database**: Multiple database support (MySQL/MariaDB, PostgreSQL, SQLite, MSSQL)
- **Frontend**: JavaScript (ES6+), CSS
- **Build Tools**: 
  - Composer for PHP dependencies
  - npm/gulp for frontend assets
  - PHPUnit for testing
- **Testing Frameworks**: PHPUnit for unit and functional tests

## Development Environment Setup

### PHP Dependencies
```bash
cd phpBB
php ../composer.phar install --dev
cd ..
```

### Frontend Dependencies
```bash
npm install
```

### Alternative Development Environments
- Vagrant (see `phpBB/docs/vagrant.md`)
- GitHub Codespaces (see `phpBB/docs/codespaces.md`)

## Coding Standards and Guidelines

### PHP Standards
- Follow **PSR-12** coding style
- Apply **SOLID** principles
- Use **MVC architecture** patterns
- See detailed guidelines: https://area51.phpbb.com/docs/dev/development/coding_guidelines.html

### Security Best Practices
- **Always** validate and sanitize user input
- Use prepared statements for database queries to prevent SQL injection
- Protect against XSS attacks by properly escaping output
- Implement CSRF protection for forms
- Never commit secrets or credentials

### Code Organization
- Use Composer autoloading (PSR-4)
- Keep dependencies managed through `phpBB/composer.json`
- Frontend assets managed through `package.json`

## Testing

### Running PHP Tests
```bash
# Run all tests
phpBB/vendor/bin/phpunit

# Run specific test groups
phpBB/vendor/bin/phpunit --group functional
phpBB/vendor/bin/phpunit --group slow

# With memory limit adjustment
phpBB/vendor/bin/phpunit -d memory_limit=2048M
```

### Test Configuration
- Unit tests use SQLite by default
- Create `tests/test_config.php` for other database configurations
- See `tests/RUNNING_TESTS.md` for comprehensive testing documentation

### Test Requirements
- Write unit tests for new functionality
- Include functional tests where appropriate
- Ensure tests pass before submitting PRs
- Follow existing test patterns and conventions

## Build and Linting

### Frontend Linting
```bash
# Run ESLint
npm run lint

# Run Stylelint
npx stylelint "**/*.css"
```

### Frontend Build
```bash
# Build frontend assets
gulp
```

## Architecture Patterns

### MVC Structure
- Models: Database interactions and business logic
- Views: Template files for rendering
- Controllers: Request handling and response coordination

### Dependency Injection
- Uses Symfony Dependency Injection component
- Services defined in configuration files

### Event System
- phpBB uses an event-driven architecture
- See `phpBB/docs/events.md` for event documentation
- Add events when extending functionality

## Git Workflow

### Before Submitting PRs
1. Create/reference a ticket: https://tracker.phpbb.com
2. Follow Git contribution guidelines: https://area51.phpbb.com/docs/dev/development/git.html
3. Run tests to ensure no regressions
4. Ensure code follows coding standards
5. Update documentation if needed

### Commit Messages
- Write clear, descriptive commit messages
- Reference ticket numbers where applicable

## Documentation

- Main documentation: https://area51.phpbb.com/docs/dev/index.html
- API documentation generated with Doctum
- Update relevant docs when changing functionality

## Common Tasks

### Adding a New Feature
1. Create a ticket on tracker.phpbb.com
2. Write tests first (TDD approach)
3. Implement the feature following coding standards
4. Update documentation
5. Run all tests
6. Submit a pull request

### Bug Fixes
1. Reference existing ticket or create one
2. Write a failing test that reproduces the bug
3. Fix the bug
4. Ensure the test passes
5. Run full test suite
6. Submit a pull request

### Database Changes
- Use Doctrine DBAL for database operations
- Support multiple database systems
- Write migration scripts when needed
- Test against different database backends

## Important Files and Directories

- `phpBB/` - Main application code
- `tests/` - Test files
- `phpBB/docs/` - Additional documentation
- `.github/` - GitHub-specific configuration and workflows
- `build/` - Build scripts and configurations
- `phpunit.xml.dist` - PHPUnit configuration
- `composer.json` - PHP dependencies (inside phpBB directory)
- `package.json` - Frontend dependencies

## Custom Agents

A PHP developer custom agent is available at `.github/agents/php-dev.agent.md`. This agent specializes in:
- Writing and refactoring PHP code using PSR-12 and SOLID principles
- Implementing secure coding practices
- Managing dependencies with Composer
- Test-driven development with PHPUnit

Delegate PHP-specific tasks to this agent when appropriate.

## Additional Resources

- Community: https://www.phpbb.com
- Development forum: https://area51.phpbb.com
- Issue tracker: https://tracker.phpbb.com
- Contributing guide: `.github/CONTRIBUTING.md`
- Security policy: `SECURITY.md`

## Tips for AI Assistants

- Always check existing patterns before implementing new code
- Prefer existing libraries and frameworks over creating new ones
- Security is paramount - validate all inputs, sanitize all outputs
- Test coverage is important - write tests for all new code
- Follow the established architecture and patterns
- When in doubt, reference the official documentation
- Make minimal, focused changes rather than large refactors
- Respect the multi-database support - don't assume MySQL-only
