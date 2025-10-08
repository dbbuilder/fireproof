# Contributing to FireProof

Thank you for your interest in contributing to FireProof! This document provides guidelines and instructions for contributing to the project.

## Code of Conduct

By participating in this project, you agree to maintain a respectful and inclusive environment for all contributors.

## How to Contribute

### Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates. When creating a bug report, include:

- **Clear title and description**
- **Steps to reproduce** the behavior
- **Expected behavior** vs actual behavior
- **Screenshots** if applicable
- **Environment details** (OS, browser, .NET version, etc.)

### Suggesting Enhancements

Enhancement suggestions are welcome! Please provide:

- **Clear title and description**
- **Use case** for the enhancement
- **Expected behavior**
- **Alternative solutions** considered

### Pull Requests

1. **Fork the repository** and create your branch from `develop`
2. **Follow coding standards** outlined below
3. **Write or update tests** for your changes
4. **Update documentation** as needed
5. **Ensure all tests pass**
6. **Create a pull request** with a clear description

## Development Workflow

### Branch Naming

- `feature/short-description` - New features
- `bugfix/issue-number-description` - Bug fixes
- `hotfix/critical-issue` - Urgent production fixes
- `docs/what-changed` - Documentation updates

### Commit Messages

Follow conventional commits format:

```
type(scope): subject

body (optional)

footer (optional)
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

**Examples:**
```
feat(inspections): add offline inspection queue
fix(barcode): resolve scanning issues on iOS
docs(readme): update installation instructions
```

## Coding Standards

### C# / .NET Backend

**General Guidelines:**
- Follow Microsoft C# coding conventions
- Use meaningful variable and method names
- Add XML documentation comments for public APIs
- Keep methods focused and under 50 lines when possible
- Use async/await for I/O operations
- Always handle exceptions appropriately

**Naming Conventions:**
```csharp
// Classes, methods, properties: PascalCase
public class InspectionService { }
public async Task<Inspection> GetInspectionAsync(Guid id) { }

// Private fields: _camelCase
private readonly ILogger<InspectionService> _logger;

// Local variables, parameters: camelCase
var inspection = await GetInspectionAsync(inspectionId);
```

**Code Structure:**
```csharp
// Order of class members:
// 1. Private fields
// 2. Constructors
// 3. Public properties
// 4. Public methods
// 5. Private methods

public class ExampleService
{
    private readonly ILogger _logger;
    
    public ExampleService(ILogger<ExampleService> logger)
    {
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));
    }
    
    public async Task<Result> DoSomethingAsync(Parameters params)
    {
        try
        {
            // Implementation with proper error handling
            _logger.LogInformation("Operation started");
            // ... 
            return result;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Operation failed");
            throw;
        }
    }
}
```

**SQL Guidelines:**
- Use T-SQL for all database scripts
- No semicolons at end of statements (per project preference)
- Always use stored procedures (no dynamic SQL)
- Add inline comments for complex logic
- Use PRINT statements for debugging
- Parameterize all queries

### Vue.js / JavaScript Frontend

**General Guidelines:**
- Follow Vue.js 3 Composition API style guide
- Use TypeScript for complex logic (optional but recommended)
- Keep components under 200 lines
- Use meaningful component and variable names
- Add JSDoc comments for complex functions

**Component Structure:**
```vue
<template>
  <!-- Template follows a logical order -->
  <div class="component-root">
    <!-- Content -->
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'

// Props
const props = defineProps({
  /* ... */
})

// Emits
const emit = defineEmits(['update', 'delete'])

// State
const data = ref([])
const isLoading = ref(false)

// Computed
const filteredData = computed(() => {
  /* ... */
})

// Methods
const fetchData = async () => {
  /* ... */
}

// Lifecycle
onMounted(() => {
  fetchData()
})
</script>

<style scoped>
/* Use Tailwind classes primarily, scoped styles for component-specific needs */
</style>
```

**Naming Conventions:**
```javascript
// Components: PascalCase
// Component files: PascalCase.vue
import InspectionList from './InspectionList.vue'

// Variables, functions: camelCase
const inspectionData = ref([])
const fetchInspections = async () => { }

// Constants: UPPER_SNAKE_CASE
const MAX_RETRIES = 3
```

**CSS/Tailwind:**
- Prefer Tailwind utility classes
- Use custom CSS only when Tailwind is insufficient
- Follow mobile-first responsive design
- Ensure accessibility (proper color contrast, semantic HTML)

## Testing Requirements

### Backend Tests
- Unit test coverage: minimum 80%
- Integration tests for all API endpoints
- Test happy paths and error conditions
- Use meaningful test names: `Should_ExpectedBehavior_When_Condition()`

```csharp
[Fact]
public async Task Should_ReturnInspection_When_IdExists()
{
    // Arrange
    var expected = CreateTestInspection();
    
    // Act
    var result = await _service.GetInspectionAsync(expected.Id);
    
    // Assert
    Assert.NotNull(result);
    Assert.Equal(expected.Id, result.Id);
}
```

### Frontend Tests
- Unit tests for complex logic
- Component tests for critical components
- E2E tests for main user workflows
- Test accessibility

## Documentation

### Code Documentation
- Add XML comments for all public APIs (C#)
- Add JSDoc comments for complex functions (JavaScript)
- Include examples in documentation when helpful
- Update README.md for significant changes

### API Documentation
- Keep Swagger/OpenAPI documentation current
- Include request/response examples
- Document all error codes
- Note any authentication requirements

## Pull Request Process

1. **Update your fork** with latest from `develop` branch
2. **Create feature branch** from `develop`
3. **Make your changes** following guidelines above
4. **Write/update tests** to maintain coverage
5. **Run all tests locally** and ensure they pass
6. **Update documentation** if needed
7. **Commit with meaningful messages**
8. **Push to your fork**
9. **Create pull request** against `develop` branch

### PR Description Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Unit tests added/updated
- [ ] Integration tests added/updated
- [ ] Manual testing completed

## Checklist
- [ ] Code follows project style guidelines
- [ ] Self-review completed
- [ ] Comments added for complex code
- [ ] Documentation updated
- [ ] No new warnings generated
- [ ] Tests pass locally

## Screenshots (if applicable)
Add screenshots for UI changes
```

## Review Process

- All PRs require at least one approval
- Address reviewer feedback promptly
- Keep discussions professional and constructive
- Be open to suggestions and alternative approaches

## Questions?

- Open an issue for questions
- Tag maintainers if urgent
- Join discussions for design decisions

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing to FireProof! 🔥
