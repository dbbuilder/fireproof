# Contributing to FireProof

Thank you for your interest in contributing to FireProof! We welcome contributions from the community.

## Code of Conduct

Be respectful, inclusive, and professional in all interactions.

## Getting Started

1. Fork the repository
2. Clone your fork locally
3. Create a branch for your feature or bugfix
4. Make your changes
5. Test thoroughly
6. Submit a pull request

## Development Setup

See the [README.md](README.md) for detailed setup instructions.

## Pull Request Process

1. Update documentation as needed
2. Add tests for new features
3. Ensure all tests pass
4. Update CHANGELOG.md (if applicable)
5. Request review from maintainers

## Coding Standards

### Backend (.NET/C#)
- Follow Microsoft C# coding conventions
- Use meaningful variable and method names
- Add XML documentation comments for public APIs
- Write unit tests with 80%+ coverage
- Use async/await for I/O operations
- No dynamic SQL - stored procedures only

### Frontend (Vue.js)
- Use Composition API
- Follow Vue.js style guide
- Use TypeScript where possible
- Write component tests
- Use Tailwind utility classes
- Keep components focused and reusable

### Database (T-SQL)
- No semicolons at end of statements
- Add inline comments for complex logic
- Print dynamic SQL before execution
- Use parameterized queries always
- Optimize indexes for query patterns

## Commit Messages

Use conventional commit format:
- `feat:` new feature
- `fix:` bug fix
- `docs:` documentation changes
- `refactor:` code refactoring
- `test:` test additions/changes
- `chore:` maintenance tasks

Example: `feat: add barcode scanning to mobile app`

## Reporting Issues

Use GitHub Issues with:
- Clear description of the problem
- Steps to reproduce
- Expected vs actual behavior
- Environment details
- Screenshots if applicable

## Feature Requests

We welcome feature requests! Please:
- Check existing issues first
- Describe the use case clearly
- Explain the benefit
- Consider implementation approach

## Questions?

Open a GitHub Discussion or contact the maintainers.

Thank you for contributing! 🚒
