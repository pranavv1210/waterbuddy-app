```markdown
# waterbuddy-app Development Patterns

> Auto-generated skill from repository analysis

## Overview
This skill teaches you the core development patterns and conventions used in the `waterbuddy-app` repository, a TypeScript codebase without a detected framework. You'll learn file naming, import/export styles, commit practices, and how to write and run tests. This guide is ideal for contributors aiming for consistency and maintainability in the project.

## Coding Conventions

### File Naming
- Use **snake_case** for all file names.
  - Example: `user_profile.ts`, `water_tracker.test.ts`

### Import Style
- Use **relative imports** for referencing other modules.
  - Example:
    ```typescript
    import { calculateIntake } from './intake_utils';
    ```

### Export Style
- Use **named exports** rather than default exports.
  - Example:
    ```typescript
    // intake_utils.ts
    export function calculateIntake(weight: number): number {
      // ...
    }
    ```

### Commit Patterns
- Commit messages are **freeform** (no enforced prefixes), averaging 34 characters.
  - Example: `fix hydration calculation bug`

## Workflows

### Adding a New Module
**Trigger:** When you need to add a new feature or utility.
**Command:** `/add-module`

1. Create a new file using snake_case (e.g., `hydration_reminder.ts`).
2. Write your TypeScript code using named exports.
3. Use relative imports to include dependencies.
4. Add corresponding test file as `hydration_reminder.test.ts`.
5. Commit your changes with a clear, concise message.

### Writing and Running Tests
**Trigger:** When you add or modify functionality.
**Command:** `/run-tests`

1. Create or update a test file with the pattern `*.test.ts`.
2. Write test cases for your functions or modules.
3. Use the project's test runner (framework unknown; check project scripts or documentation).
4. Run the tests and ensure all pass before committing.

### Refactoring Code
**Trigger:** When improving or restructuring existing code.
**Command:** `/refactor`

1. Identify the module(s) to refactor.
2. Update code using named exports and relative imports.
3. Rename files as needed to maintain snake_case.
4. Update or add tests to cover changes.
5. Run all tests to verify correctness.
6. Commit with a descriptive message.

## Testing Patterns

- Test files follow the `*.test.ts` naming convention.
- The testing framework is **unknown**; check for project documentation or scripts for details.
- Place test files alongside or near the modules they test.
- Example test file:
  ```typescript
  // water_tracker.test.ts
  import { calculateIntake } from './intake_utils';

  test('calculates intake correctly', () => {
    expect(calculateIntake(70)).toBe(2100);
  });
  ```

## Commands
| Command        | Purpose                                      |
|----------------|----------------------------------------------|
| /add-module    | Scaffold and add a new module                |
| /run-tests     | Run all test files matching `*.test.ts`       |
| /refactor      | Refactor code while following conventions     |
```
