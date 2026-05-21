```markdown
# AionUi-auto Development Patterns

> Auto-generated skill from repository analysis

## Overview
This skill teaches you the core development patterns and conventions used in the `AionUi-auto` TypeScript codebase. You'll learn about file naming, import/export styles, commit conventions, and how to write and organize tests. This guide is ideal for contributors aiming to maintain consistency and quality in the project.

## Coding Conventions

### File Naming
- Use **camelCase** for all file names.
  - Example: `userProfile.ts`, `dataFetcher.test.ts`

### Import Style
- Use **relative imports** for modules within the project.
  - Example:
    ```typescript
    import { fetchData } from './dataFetcher';
    ```

### Export Style
- Use **named exports** for all modules.
  - Example:
    ```typescript
    // dataFetcher.ts
    export function fetchData() { ... }
    ```

### Commit Messages
- Follow the **Conventional Commits** pattern.
- Use the `feat` prefix for new features.
  - Example:
    ```
    feat: add user profile component
    ```

## Workflows

### Adding a New Feature
**Trigger:** When implementing a new feature or module  
**Command:** `/add-feature`

1. Create a new TypeScript file using camelCase naming.
2. Implement your feature using named exports.
3. Import dependencies using relative paths.
4. Write a corresponding test file named `featureName.test.ts`.
5. Commit your changes with a message starting with `feat:`.
6. Push your branch and open a pull request.

### Writing Tests
**Trigger:** When adding or updating code that requires testing  
**Command:** `/write-test`

1. Create a test file with the pattern `featureName.test.ts`.
2. Write tests for all exported functions/components.
3. Use the project's preferred (unknown) testing framework.
4. Run tests to ensure they pass before committing.

## Testing Patterns

- Test files use the `*.test.*` naming convention.
  - Example: `dataFetcher.test.ts`
- Each test file should correspond to a single module or feature.
- The specific testing framework is not detected; follow existing patterns in the repository.

## Commands
| Command        | Purpose                                 |
|----------------|-----------------------------------------|
| /add-feature   | Guide for adding a new feature/module   |
| /write-test    | Steps for writing and organizing tests  |
```
