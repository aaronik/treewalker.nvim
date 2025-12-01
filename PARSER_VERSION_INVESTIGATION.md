# Tree-sitter Parser Version Investigation

## Problem Summary
CI tests are failing on comment-related navigation tests (TypeScript and Java), but passing locally and in Ubuntu Docker.

## Root Cause
**Different tree-sitter parser versions between environments.**

## Evidence

### Parser File Sizes

#### Local (macOS)
- TypeScript parser: 1,438,792 bytes (modified: 2025-04-28)
- Java parser: 447,288 bytes (modified: 2025-11-29)
- Neovim: 0.11.5

#### CI (Ubuntu GitHub Actions)
- TypeScript parser: 1,431,200 bytes (modified: 2025-12-01 - freshly cloned)
- Java parser: Size not captured but freshly cloned (modified: 2025-12-01)
- Neovim: 0.11.5

**TypeScript parser is 7,592 bytes smaller on CI!**

### Failing Test
```
Test: "Moves out from Ok class comment to class declaration"
Location: tests/treewalker/typescript_spec.lua:136

Expected: Move from comment (line 121, col 3) to class declaration (line 119, col 1)
Actual (CI): Stay at comment (line 121, col 3)

Code context (typescript.ts:119-124):
119: class Ok {
120:
121:   /**
122:     * whats blah blah
123:     */
124:   constructor(who: What) {
```

The test expects `move_out()` from inside the `/**` comment to jump to the `class Ok {` declaration, but on CI it remains stuck in the comment.

## Why This Happens

### CI Workflow
The CI workflow clones nvim-treesitter fresh on every run:
```yaml
- name: Install nvim-treesitter
  run: |
    mkdir -p $HOME/.local/share/nvim/lazy/
    git clone https://github.com/nvim-treesitter/nvim-treesitter.git
    mv nvim-treesitter $HOME/.local/share/nvim/lazy/
```

This means:
1. CI always gets the **latest** nvim-treesitter code
2. CI always gets the **latest** parser binaries
3. Parser changes upstream can break tests without any code changes

### Local/Docker
- Local has older parser binaries that haven't been updated
- Docker test runs in a clean environment but builds similarly to local
- Both use whatever parser version was current when last installed

## Different Tree Structures

The different parser versions produce different AST structures for the same code, particularly around:
- Comment nodes
- Comment associations with following code
- Parent/child relationships in the tree

This affects Treewalker's navigation logic, which relies on the tree structure to determine where to move.

## Solutions

### Option 1: Pin Parser Versions
Pin specific nvim-treesitter commits in CI to match development environment:

```yaml
- name: Install nvim-treesitter
  run: |
    mkdir -p $HOME/.local/share/nvim/lazy/
    git clone --branch <specific-tag-or-commit> https://github.com/nvim-treesitter/nvim-treesitter.git
    mv nvim-treesitter $HOME/.local/share/nvim/lazy/
```

**Pros**: Consistent behavior across environments
**Cons**: Must manually update when wanting newer parsers

### Option 2: Make Tests Parser-Version-Agnostic
Redesign comment-related tests to be more flexible about parser variations.

**Pros**: More robust to parser changes
**Cons**: May miss real bugs, harder to write precise tests

### Option 3: Document Parser Versions as Test Dependency
Accept that tests depend on parser versions and document which versions are tested.

**Pros**: Simple, honest about dependencies
**Cons**: Tests may fail when parsers update

### Option 4: Test Against Multiple Parser Versions
Run CI matrix with different nvim-treesitter versions.

**Pros**: Catches compatibility issues early
**Cons**: More complex CI, slower tests

## Verified Versions

### Local Environment
- nvim-treesitter: **v0.10.0**
- Commit: `42fc28ba docs(readme)!: announce archiving of master branch`

### CI Environment (before fix)
- nvim-treesitter: **latest main branch** (constantly changing)

## Solution Applied

**Pinned nvim-treesitter to v0.10.0 in CI** to match local environment.

Changed in `.github/workflows/test.yml`:
```yaml
git clone --depth 1 --branch v0.10.0 https://github.com/nvim-treesitter/nvim-treesitter.git
```

This ensures:
- Consistent parser behavior across environments
- Tests won't randomly break when parsers update
- Explicit control over when to adopt new parser versions

## Future Considerations

1. When updating parser versions, test thoroughly for navigation changes
2. Consider adding parser version to test output for debugging
3. Document any parser-specific workarounds in code
4. Periodically review and update to newer parser versions
5. Consider running CI with multiple parser versions to catch regressions early
