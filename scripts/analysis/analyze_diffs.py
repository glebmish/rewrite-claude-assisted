import sys
import json
import re
import os
from unidiff import PatchSet

# Enable verbose troubleshooting logs with: ANALYZE_DIFFS_DEBUG=1
DEBUG = os.environ.get('ANALYZE_DIFFS_DEBUG', '0') == '1'

def debug_log(message, **kwargs):
    """Print debug information to stderr if DEBUG is enabled."""
    if DEBUG:
        print(f"[DEBUG] {message}", file=sys.stderr)
        for key, value in kwargs.items():
            print(f"[DEBUG]   {key}: {value}", file=sys.stderr)

# List of file paths to exclude from the diff analysis.
# These files will be skipped, and their changes will not be counted.
EXCLUDED_FILES = [
    "gradlew.bat",
    "gradlew",
    "rewrite.gradle"  # Temporary build script, not application code
]

def remove_binary_diffs(diff_content):
    """
    Removes binary file diffs from the diff content.
    Binary file diffs cause unidiff to fail with trailing newline errors.

    Binary file diffs look like:
    diff --git a/path/to/file b/path/to/file
    new file mode 100644
    index 0000000..cb76119
    --- /dev/null
    +++ b/path/to/file
    Binary files differ
    """
    # Pattern to match binary file diff blocks
    # Match from "diff --git" up to and including "Binary files differ" line
    # Use negative lookahead to stop before next "diff --git" or end of string
    binary_diff_pattern = r'diff --git [^\n]*\n(?:(?!diff --git).*\n)*?Binary files[^\n]*\n?'

    # Remove all binary diff blocks
    cleaned_content = re.sub(binary_diff_pattern, '', diff_content, flags=re.MULTILINE)

    return cleaned_content

def clean_malformed_hunks(diff_content):
    """
    Fixes malformed hunk headers where recipe names are appended.

    OpenRewrite generates hunks like:
    @@ -1,7 +1,8 @@ com.yourorg.RecipeName

    Should be:
    @@ -1,7 +1,8 @@

    This removes any text after the closing @@ to prevent parsing errors.
    """
    # Remove any text after the closing @@ in hunk headers
    cleaned = re.sub(
        r'^(@@ -\d+(?:,\d+)? \+\d+(?:,\d+)? @@).*$',
        r'\1',
        diff_content,
        flags=re.MULTILINE
    )
    return cleaned

def deduplicate_file_diffs(diff_content):
    """
    Removes duplicate diff sections for the same file.

    OpenRewrite sometimes generates multiple diffs for the same file
    (e.g., gradle-wrapper.properties, gradle-wrapper.jar).
    Keeps only the first occurrence.
    """
    # Split into diff sections
    file_sections = re.split(r'(?=^diff --git )', diff_content, flags=re.MULTILINE)

    seen_files = set()
    unique_sections = []

    for section in file_sections:
        if not section.strip():
            continue

        # Extract file path from "diff --git a/path b/path"
        match = re.search(r'^diff --git a/(.*?) b/', section, re.MULTILINE)
        if match:
            file_path = match.group(1)
            if file_path not in seen_files:
                seen_files.add(file_path)
                unique_sections.append(section)
        else:
            # Keep sections without clear file paths (shouldn't happen)
            unique_sections.append(section)

    return ''.join(unique_sections)

def remove_excluded_files(diff_content):
    """
    Removes diff sections for excluded files from the diff content.

    This filters out files in EXCLUDED_FILES (gradlew, gradlew.bat, rewrite.gradle)
    before parsing, so they don't appear in the cleaned content output.
    """
    # Split into diff sections
    file_sections = re.split(r'(?=^diff --git )', diff_content, flags=re.MULTILINE)

    kept_sections = []
    removed_count = 0

    for section in file_sections:
        if not section.strip():
            continue

        # Extract file path from "diff --git a/path b/path"
        match = re.search(r'^diff --git a/(.*?) b/', section, re.MULTILINE)
        if match:
            file_path = match.group(1)
            if file_path not in EXCLUDED_FILES:
                kept_sections.append(section)
            else:
                removed_count += 1
                debug_log(f"Removing excluded file section: {file_path}")
        else:
            # Keep sections without clear file paths
            kept_sections.append(section)

    return ''.join(kept_sections), removed_count

def parse_diff_to_set(file_path):
    """
    Parses a diff file and converts it into a set of canonical change tuples.
    Each change is represented as (file_path, change_type, line_number, content).
    Line number distinguishes identical content at different positions.
    """
    changes = set()
    try:
        # Read file in binary mode first to preserve all content
        with open(file_path, 'rb') as f:
            raw_content = f.read()

        # Decode and normalize line endings (replace CRLF with LF, then strip any remaining \r)
        diff_content = raw_content.decode('utf-8').replace('\r\n', '\n').replace('\r', '\n')

        original_size = len(diff_content)
        original_lines = diff_content.count('\n')
        original_diff_sections = len(re.findall(r'^diff --git', diff_content, re.MULTILINE))

        debug_log(f"ORIGINAL {file_path}:",
                  size_bytes=original_size,
                  total_lines=original_lines,
                  diff_sections=original_diff_sections)

        # PREPROCESSING PIPELINE:
        # 1. Remove binary file diffs
        diff_content = remove_binary_diffs(diff_content)
        after_binary = len(diff_content)
        debug_log("After binary removal:",
                  size_bytes=after_binary,
                  removed_bytes=original_size - after_binary)

        # 2. Deduplicate file sections (OpenRewrite sometimes duplicates Gradle wrapper files)
        diff_content = deduplicate_file_diffs(diff_content)
        after_dedup = len(diff_content)
        debug_log("After deduplication:",
                  size_bytes=after_dedup,
                  removed_bytes=after_binary - after_dedup)

        # 3. Clean malformed hunk headers (OpenRewrite appends recipe names to @@ headers)
        diff_content = clean_malformed_hunks(diff_content)
        after_clean = len(diff_content)
        debug_log("After hunk cleaning:",
                  size_bytes=after_clean,
                  removed_bytes=after_dedup - after_clean)

        # 4. Remove excluded files (gradlew, gradlew.bat, rewrite.gradle)
        diff_content, excluded_count = remove_excluded_files(diff_content)
        after_exclusion = len(diff_content)
        debug_log("After excluded file removal:",
                  size_bytes=after_exclusion,
                  removed_bytes=after_clean - after_exclusion,
                  excluded_files=excluded_count)

        if DEBUG:
            print(f"\n[DEBUG] ===== CLEANED CONTENT for {file_path} =====", file=sys.stderr)
            print(diff_content, file=sys.stderr)
            print(f"[DEBUG] ===== END CLEANED CONTENT =====\n", file=sys.stderr)

        # Parse the cleaned content
        patch_set = PatchSet(diff_content)
        debug_log("Parsed with unidiff:", files_in_patch=len(patch_set))

        for patched_file in patch_set:
            file_changes = 0
            # Use the target_file path for additions and source_file for removals
            # to correctly handle file creation and deletion.
            for hunk in patched_file:
                for line in hunk:
                    # Use line.value to get the raw line content without +/-
                    content = line.value
                    if line.is_added:
                        # Include target line number to distinguish same content at different positions
                        changes.add((patched_file.target_file, 'add', line.target_line_no, content))
                        file_changes += 1
                    elif line.is_removed:
                        # Include source line number to distinguish same content at different positions
                        changes.add((patched_file.source_file, 'remove', line.source_line_no, content))
                        file_changes += 1

            debug_log(f"Extracted from {patched_file.path}:", changes=file_changes)
    except FileNotFoundError:
        print(f'''{{"error": "File not found: {file_path}"}}''', file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f'''{{"error": "Error parsing diff file: {file_path}", "details": "{str(e)}"}}''', file=sys.stderr)
        sys.exit(1)
        
    return changes

def main():
    if len(sys.argv) != 3:
        print('''{{"error": "Usage: python analyze_diffs.py <pr_diff_path> <recipe_diff_path>"}}''', file=sys.stderr)
        sys.exit(1)

    pr_diff_path = sys.argv[1]
    recipe_diff_path = sys.argv[2]

    debug_log("\n" + "="*80)
    debug_log("PARSING PR DIFF")
    debug_log("="*80)
    set_g = parse_diff_to_set(pr_diff_path)
    debug_log(f"\nTotal changes extracted from PR: {len(set_g)}")

    debug_log("\n" + "="*80)
    debug_log("PARSING RECIPE DIFF")
    debug_log("="*80)
    set_r = parse_diff_to_set(recipe_diff_path)
    debug_log(f"\nTotal changes extracted from recipe: {len(set_r)}")

    debug_log("\n" + "="*80)
    debug_log("COMPARING CHANGES")
    debug_log("="*80)

    # Set Operations
    tp_set = set_g.intersection(set_r)
    # True Positives (TP): Changes present in both the ground truth and the recipe output.
    tp = len(tp_set)

    fn_set = set_g.difference(set_r)
    # False Negatives (FN): Changes required by the PR but missed by the recipe.
    # These are "errors of omission" - the recipe failed to do something it should have.
    fn = len(fn_set)

    fp_set = set_r.difference(set_g)
    # False Positives (FP): Changes made by the recipe that were not in the original PR.
    # These are "errors of commission" - the recipe did something it shouldn't have.
    fp = len(fp_set)

    if DEBUG:
        # Group changes by file for easier reading
        def group_by_file(change_set):
            by_file = {}
            for file_path, change_type, line_no, content in change_set:
                if file_path not in by_file:
                    by_file[file_path] = []
                by_file[file_path].append((change_type, line_no, content))
            return by_file

        print(f"\n[DEBUG] TRUE POSITIVES (TP={tp}):", file=sys.stderr)
        tp_by_file = group_by_file(tp_set)
        for file_path, changes in sorted(tp_by_file.items()):
            print(f"[DEBUG]   {file_path}: {len(changes)} changes", file=sys.stderr)
            for change_type, line_no, content in changes:
                preview = content[:60].replace('\n', '\\n')
                print(f"[DEBUG]     [L{line_no}] [{change_type}] {preview}", file=sys.stderr)

        print(f"\n[DEBUG] FALSE POSITIVES (FP={fp}):", file=sys.stderr)
        fp_by_file = group_by_file(fp_set)
        for file_path, changes in sorted(fp_by_file.items()):
            print(f"[DEBUG]   {file_path}: {len(changes)} changes", file=sys.stderr)
            for change_type, line_no, content in changes:
                preview = content[:60].replace('\n', '\\n')
                print(f"[DEBUG]     [L{line_no}] [{change_type}] {preview}", file=sys.stderr)

        print(f"\n[DEBUG] FALSE NEGATIVES (FN={fn}):", file=sys.stderr)
        fn_by_file = group_by_file(fn_set)
        for file_path, changes in sorted(fn_by_file.items()):
            print(f"[DEBUG]   {file_path}: {len(changes)} changes", file=sys.stderr)
            for change_type, line_no, content in changes:
                preview = content[:60].replace('\n', '\\n')
                print(f"[DEBUG]     [L{line_no}] [{change_type}] {preview}", file=sys.stderr)

    # Metric Calculation
    total_expected_changes = tp + fn
    total_resulting_changes = tp + fp

    # Fix: Use 0.0 instead of 1.0 when no predictions are made
    # (1.0 precision with 0 predictions is nonsensical)
    precision = 0.0 if (tp + fp) == 0 else tp / (tp + fp)
    recall = 0.0 if (tp + fn) == 0 else tp / (tp + fn)
    f1_score = 0.0 if (precision + recall) == 0 else 2 * (precision * recall) / (precision + recall)
    
    is_perfect_match = (fp == 0 and fn == 0)

    # JSON Output
    results = {
        "diff_files": {
            "pr_diff": pr_diff_path,
            "recipe_diff": recipe_diff_path
        },
        "metrics": {
            "total_expected_changes": total_expected_changes,
            "total_resulting_changes": total_resulting_changes,
            "true_positives": tp,
            "false_positives": fp,
            "false_negatives": fn,
            "precision": round(precision, 4),
            "recall": round(recall, 4),
            "f1_score": round(f1_score, 4),
            "is_perfect_match": is_perfect_match
        }
    }

    print(json.dumps(results, indent=2))

if __name__ == "__main__":
    main()
