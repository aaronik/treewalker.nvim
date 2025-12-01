# CI Test Failures Investigation - Current Status

**Last Updated**: 2025-11-30 (Session 1)

## Problem Statement

CI tests are failing on comment navigation tests (Java), but tests pass locally. This is preventing merges despite working code.

### Failing Tests
- `java_spec.lua`: "swaps methods down"
- `java_spec.lua`: "swaps methods up"
- `java_spec.lua`: "moves out from inside javadoc to class"

All three tests involve navigating around or from within Java comment blocks.

### Expected vs Actual Behavior

**"moves out from inside javadoc to class" test:**
- **Expected**: From javadoc comment (line 31) → class declaration (line 13)
- **Actual (CI)**: Stays in comment block (line 30/31)
- **Actual (Local)**: Works correctly, moves to line 13

## Current Environment Status

### Local Environment
- **Neovim**: 0.11.5
- **nvim-treesitter**: v0.10.0
- **TypeScript parser**: 1,438,792 bytes (modified: 2025-04-28)
- **Java parser**: 447,288 bytes (modified: 2025-11-30 19:41)
- **Tests**: PASSING ✅

### CI Environment
- **Neovim**: 0.11.5 (same)
- **nvim-treesitter**: v0.10.0 (pinned in workflow)
- **Expected parser sizes**: Should match local
- **Tests**: FAILING ❌

## Timeline of Actions

### Discovery Phase
1. Identified that CI was using latest nvim-treesitter (changing daily)
2. Found TypeScript parser was 7.5 KB smaller on CI (1,431,200 vs 1,438,792 bytes)
3. Discovered comment navigation tests failing in TypeScript on CI
4. Created investigation tools:
   - `check_parsers.lua` - Compare parser info
   - `Makefile` targets: `check-parsers`, `save-trees`
   - `PARSER_VERSION_INVESTIGATION.md` - Initial analysis

### First Fix Attempt
1. **Pinned nvim-treesitter to v0.10.0** in `.github/workflows/test.yml`
2. Result: CI **PASSED** ✅ (run 19810138349)
3. Believed problem was solved

### Current Situation
1. Cleaned up investigation files
2. Accidentally removed some code, restored it
3. CI now **FAILING AGAIN** ❌ with v0.10.0 still pinned
4. Tests still passing locally with same v0.10.0

## What We Know

### Facts
1. ✅ Both local and CI use Neovim 0.11.5
2. ✅ Both local and CI use nvim-treesitter v0.10.0 (pinned in workflow)
3. ✅ Tests pass locally consistently
4. ❌ Tests fail on CI consistently
5. ❌ Same test/same version fails on CI, passes locally
6. ⚠️ One CI run DID pass with v0.10.0 pinned (before cleanup)

### Parser Version Mystery
Even though both environments claim v0.10.0, there may be:
- Different parser binary versions within v0.10.0
- Platform differences (macOS vs Ubuntu)
- Compiler differences affecting parser behavior
- Timing of when parsers were built

### The Smoking Gun
The fact that **one CI run passed** with v0.10.0, then **failed** with the same v0.10.0 after code cleanup strongly suggests:
- The "cleanup" accidentally changed functional code, OR
- There's something non-deterministic in the CI environment, OR
- Parser binaries are being rebuilt differently despite same version tag

## Theories

### Theory 1: Platform-Specific Parser Behavior ⭐ LIKELY
Tree-sitter parser binaries are compiled C code. The same parser grammar version might produce different AST structures on:
- macOS (local) vs Ubuntu (CI)
- Different C compiler versions
- Different system libraries

**Evidence**:
- Same code version, different behavior
- Both claim v0.10.0 but behave differently
- Comment node handling is platform-specific

**Next Steps**:
- Check if parser binaries actually differ despite same version
- Test if Docker Ubuntu matches CI behavior
- Consider using pre-built binaries instead of compiling

### Theory 2: Code Was Actually Changed 🤔 POSSIBLE
During "cleanup", functional code was accidentally modified beyond investigation files.

**Evidence**:
- CI passed, then failed after cleanup
- User confirms removing and restoring code

**Next Steps**:
- Diff against the passing commit (19810138349)
- Check git history carefully
- Verify all functional code is identical

### Theory 3: CI Environment Non-Determinism ❓ UNLIKELY
Something in GitHub Actions is non-deterministic.

**Evidence**:
- Weak - most CI environments are deterministic
- Would be very unusual

**Next Steps**:
- Rerun same commit multiple times
- Check for any async/timing issues in tests

### Theory 4: Parser Binary Caching Issue 🔧 POSSIBLE
nvim-treesitter compiles parsers on first install, then caches them. CI might be:
- Using cached parsers from a different run
- Not rebuilding parsers when it should
- Mixing parser versions

**Evidence**:
- Parsers are compiled, not just downloaded
- Cache behavior differs between local and CI

**Next Steps**:
- Force parser rebuild in CI workflow
- Clear any CI caches
- Use `:TSUpdate!` equivalent in CI

## Current Workflow Configuration

```yaml
- name: Install nvim-treesitter
  run: |
    mkdir -p $HOME/.local/share/nvim/lazy/
    # TODO specifying 0.10.0 is a workaround - something later than it is
    # breaking ts/java comment nodes
    git clone --depth 1 --branch v0.10.0 https://github.com/nvim-treesitter/nvim-treesitter.git
    mv nvim-treesitter $HOME/.local/share/nvim/lazy/
```

**Note**: This clones the plugin code but doesn't explicitly compile parsers. Parsers are compiled on-demand during tests.

## Investigation Tools Created

### Files
- ✅ `check_parsers.lua` - Reports parser versions and info
- ✅ `Makefile` targets - `check-parsers`, `save-trees`, `dump-treesitter-tree`
- ✅ `PARSER_VERSION_INVESTIGATION.md` - Initial detailed analysis
- ✅ `CI_INVESTIGATION_STATUS.md` (this file)

### Usage
```bash
# Check parser info locally
make check-parsers

# Dump tree structure for a file
make dump-treesitter-tree FILE=tests/fixtures/java.java

# Save both trees for comparison
make save-trees
```

## What to Try Next

### Immediate Actions
1. **Compare exact git state** between passing and failing commits
   ```bash
   git diff 19810138349 HEAD
   ```

2. **Force parser recompilation in CI** by adding to workflow:
   ```yaml
   - name: Compile parsers
     run: |
       nvim --headless -c "TSInstall! java typescript" -c "qa"
   ```

3. **Run Ubuntu Docker test locally** to match CI platform:
   ```bash
   make test-ubuntu
   ```

4. **Check actual parser binary contents** (md5/sha256):
   ```bash
   # Local
   md5 ~/.local/share/nvim/lazy/nvim-treesitter/parser/java.so

   # Add to CI workflow
   md5sum $HOME/.local/share/nvim/lazy/nvim-treesitter/parser/java.so
   ```

### Nuclear Option
If parser binaries are the issue and can't be resolved, consider:
- **Skip comment-related tests on CI** (not ideal)
- **Use pre-built parser binaries** uploaded as artifacts
- **Accept different behavior per platform** and adjust tests
- **File bug report** with nvim-treesitter about platform differences

## Useful CI Run References

- **19810138349** - ✅ PASSING with v0.10.0 pinned (before cleanup)
- **19810655535** - ❌ FAILING with v0.10.0 pinned (after cleanup)
- **19810754740** - ❌ FAILING with v0.10.0 pinned (most recent)

Compare these runs to understand what changed.

## Code Locations to Check

### Test Files
- `tests/treewalker/java_spec.lua` - Failing Java tests
- `tests/treewalker/typescript_spec.lua` - TypeScript comment tests (were failing)

### Core Navigation Code
- `lua/treewalker/movement.lua` - Main movement logic
- `lua/treewalker/targets.lua` - Target node selection
- `lua/treewalker/nodes.lua` - Node utilities
- `lua/treewalker/augment.lua` - Comment/decorator handling

**Focus**: The augment.lua file handles comment associations - this is likely where platform differences manifest.

## Key Questions to Answer

1. ❓ What is the **exact git diff** between passing (19810138349) and failing commits?
2. ❓ Do parser **binaries actually differ** despite same version tag?
3. ❓ Does `make test-ubuntu` **pass or fail locally**?
4. ❓ Can we **force parser recompilation** in CI to ensure fresh builds?
5. ❓ Are there any **LSP diagnostics or warnings** in the code?

## Notes

- Parser binaries (`.so` files) are platform-specific compiled code
- Same grammar version doesn't guarantee identical AST behavior
- Comment node handling is particularly sensitive to parser changes
- macOS and Ubuntu may produce different parser binaries from same source
- This is likely a "works on my machine" scenario with legitimate technical cause

---

**For next session**: Start by running the immediate actions above and updating this file with results.
