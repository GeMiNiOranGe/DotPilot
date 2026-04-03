# Test Design & Implementation

## Source Code to Test

### Supporting types / classes (if any)
```powershell
# Paste enum, class, or type definitions here (leave blank if none)
```

### Functions to test
```powershell
# Paste the function(s) to test here
```

### Sample test file for reference
```powershell
# Paste the sample test content here
```

## Requirements

Based on the source code above, follow these steps **in exact order**:

### 1. Input Space Analysis
List all parameters, data types, and constraints. For parameters that do not affect behavior (e.g., appearing only in log/error messages), add a brief note - no need to partition them.

### 2. Equivalence Partitioning
Partition each parameter that affects behavior. Each partition needs: name, representative value, expected behavior. If `$null` is coerced into the same partition as Empty, state that explicitly and skip the duplicate.

### 3. Decision Table
Combine partitions across parameters. List only combinations that produce different behaviors. Add a **Note block** below the table to explain:
- Which combinations are listed in the table but cannot be tested, and why (e.g., a parameter is only meaningful on a specific code path, ignored on another). These rows remain in the Decision Table; the Note explains the reason. They do not appear in the test map.
- Which assertions are only tested on a subset of combinations and why (e.g., output color is unaffected by Message, so it is only tested against a representative subset of Message combinations).
- Notes are numbered starting from 1.
- In each note, any combination references such as 'X + Y', ('X + Y'), or ('X + Y' and 'X + Z') must appear at the **end** of the sentence, not at the beginning or in the middle.

### 4. Boundary Value Analysis
Apply if there are numeric parameters, string-length constraints, or collections with clear boundaries. If not applicable, skip this section and write "(not applicable)".

### 5. State Transition Testing
Apply if the function has internal state that changes between calls (e.g., counter, cache, flag, file created on disk that affects the next call). If not applicable, skip this section and write "(not applicable)".

### 6. Other Techniques
Apply if there are special cases not covered by EP, DT, BVA, or STT (e.g., pairwise testing, use-case testing). If not applicable, skip this section and write "(not applicable)".

### 7. Test Map
Columns: ID, Context, Input, Technique, Assert
- Each `It` block is one row
- No Guard rows - a Guard is an implementation detail of the test suite, not a test case for the function's behavior
- Combinations that are not tested have no rows in the test map - the reason is already explained in the Decision Table's Note block.
- `It` blocks within the same Context that share Input and Technique columns use `^` (ditto)
- Limit 80 characters per line - abbreviate Assert names if needed

### 8. Test Structure
Write the complete `Describe/Context/It` blocks following these rules:

**Wrapper and dot-sourcing:**
- If the function under test calls external commands or functions that need to be isolated, define a mock or stub in `BeforeAll` at the appropriate level.
- Dot-source any supporting type files and the function file in `BeforeAll` at the `Describe` level.

**Mocking:**
- Use `Mock` for commands whose side effects must be suppressed or whose return values must be controlled (e.g., `Write-Host`, `Set-Content`, `Write-Log`).
- Place `Mock` inside the `Context` that needs it, or in `BeforeAll` at the `Describe` level if it applies globally.
- Use `Should -Invoke` / `Should -Not -Invoke` to assert call counts and parameter values when the behavior under test is expressed through side-effecting calls rather than return values.

**Mapping Decision Table rows to Contexts:**
- **1 Decision Table row = 1 Context** - do not merge multiple combinations into the same Context even if behavior is identical

**BeforeAll and capture:**
- If a Context has multiple assertions on the same throw -> use `BeforeAll` to capture `$script:caughtError`
- If a Context needs to capture the return value for multiple assertions -> use `BeforeAll` to capture `$script:result`.
- If a "specific-value" Context needs to reference a variable inside an `It` block, assign it to a `$script:` variable in `BeforeAll` instead of inlining it in the call.
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
- For output/side-effect functions, prefer `Should -Invoke` with `-ParameterFilter` to verify the correct arguments were passed to mocked commands.
- ID comment (`# 01`, `# 02`, …) placed above each `It` block, matching the test map

**80-character rule - line-break priority order:**
1. Break before `|` when piping into `Should`:
    ```powershell
    $script:caughtError.Exception.Message | `
        Should -BeLike "*some text*"
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
