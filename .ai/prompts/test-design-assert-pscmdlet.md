# Test Design & Implementation for Assert-* Functions

## Source Code to Test

### Exception class
```powershell
# Paste the exception class file content here
```

### Functions to test
```powershell
# Paste the Assert-* function content here
```

### Samples test file for reference
```powershell
# Paste the sample test content here
```

## Requirements

Based on the source code above, follow these steps **in exact order**:

### 1. Input Space Analysis
List all parameters, data types, and constraints. For parameters that do not affect behavior (appearing only in error messages), add a brief note - no need to partition them.

### 2. Equivalence Partitioning
Partition each parameter that affects behavior. Each partition needs: name, representative value, expected behavior. If `$null` is coerced into the same partition as Empty, state that explicitly and skip the duplicate.

### 3. Decision Table
Combine partitions across parameters. List only combinations that produce different behaviors. Add a **Note block** below the table to explain:
- Which combinations are listed in the table but cannot be tested, and why (e.g., a parameter is only meaningful when throwing, ignored on the valid path). These rows remain in the Decision Table; the Note explains the reason. They do not appear in the test map.
- Which assertions are only tested on a subset of combinations and why (e.g., Exception type/message/attribution are unaffected by Reason, so they are only tested against the Absent combinations)
- Notes are numbered starting from 1.
- In each note, any combination references such as 'X + Y', ('X + Y'), or ('X + Y' and 'X + Z') must appear at the **end** of the sentence, not at the beginning or in the middle.

### 4. Boundary Value Analysis
Apply if there are numeric parameters, string-length constraints, or collections with clear boundaries. If not applicable, skip this section and write "(not applicable)".

### 5. State Transition Testing
Apply if the function has internal state that changes between calls (e.g., counter, cache, flag). If not applicable, skip this section and write "(not applicable)".

### 6. Other Techniques
Apply if there are special cases not covered by EP, DT, BVA, or STT (e.g., pairwise testing, use-case testing). If not applicable, skip this section and write "(not applicable)".

### 7. Test Map
Columns: ID, Context, Input, Technique, Assert
- Each `It` block is one row
- No Guard rows - a Guard is an implementation detail of the test suite, not a test case for the function's behavior
- Combinations that are not tested have no rows in the test map - the reason is already explained in the Decision Table's Note block.
- `It` blocks within the same capture share Input and Technique columns using `^` (ditto)
- Limit 80 characters per line - abbreviate Assert names if needed

### 8. Test Structure
Write the complete `Describe/Context/It` blocks following these rules:

**Wrapper and dot-sourcing:**
- `Invoke-Caller` is a synthetic wrapper function, defined in `BeforeAll` at the `Describe` level
- Dot-source the class and function files in `BeforeAll` at the `Describe` level

**Mapping Decision Table rows to Contexts:**
- **1 Decision Table row = 1 Context** - do not merge multiple combinations into the same Context even if behavior is identical

**BeforeAll and capture:**
- If a Context has multiple assertions on the same throw -> use `BeforeAll` to capture `$script:caughtError`
- If a "Present" Context needs to reference Reason inside an `It` block, assign it to `$script:reason` in `BeforeAll` instead of inlining it in the call
- Place the Guard inside `BeforeAll` using:
    ```powershell
    if ($null -eq $script:caughtError) {
        throw @(
            "Guard: Invoke-Caller did not throw - all assertions in "
            "this Context are invalid."
        ) -join ''
    }
    ```
    Do not use an `It` block for a Guard. If the Guard message is long, also use `@(...) -join ''` the same way as regular strings.

**Assertions:**
- Exception type uses:
    ```powershell
    $script:caughtError.Exception | Should -BeOfType (
        [ExceptionClassName]
    )
    ```
    Do not write this inline on one line to avoid exceeding 80 characters.
- ID comment (`# 01`, `# 02`, …) placed above each `It` block, matching the test map

**80-character rule - line-break priority order:**
1. Break before `|` when piping into `Should`:
    ```powershell
    $script:caughtError.Exception.Message | `
        Should -BeLike "*'-Environment'*"
    ```
2. Break with a backtick before the next `-Parameter`:
    ```powershell
    Invoke-Caller `
        -Name "Environment" `
        -Value "" `
        -Reason $script:reason
    ```
3. Break using `@(...) -join ''` for long strings:
    ```powershell
    throw @(
        "Guard: Invoke-Caller did not throw - all assertions in "
        "this Context are invalid."
    ) -join ''
    ```
4. Backticks are only used outside script blocks `{}`. Inside `{}`, do not use backticks - break by extracting into a variable or using `-join`.

### 9. Test Design Comment Block
Place the entire analysis (input space, EP, decision table, test map) inside a `<# ... #>` block immediately before the first `Describe` line, at the top of the file. Include:
- A **List of Abbreviations** at the end in this format:
    ```
    List of Abbreviations:
    'x' - <meaning>
    AB  - <meaning>
    ```
- A `###...###` separator between sections

When writing the code in Section 8, embed the comment block from Section 9 directly before the `Describe "..." {` line, at the top of the file. Do not write the analysis separately and append it afterward.

### 10. Output
Return the test content styled consistently with the original sample test file. Style rules to preserve:
- Indentation: 4 spaces
- Use `@(...) -join ''` for multiline strings (no here-strings)
- Blank line between `It` blocks
- No blank line between `Context` and `BeforeAll`
- Absolutely no line may exceed 80 characters; if it must, apply the line-break priority order from Section 8
