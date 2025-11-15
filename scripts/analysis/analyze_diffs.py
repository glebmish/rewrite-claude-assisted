import sys
import json
import re
from unidiff import PatchSet

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
    # Matches from "diff --git" to "Binary files differ" (inclusive)
    binary_diff_pattern = r'diff --git .*?\nBinary files .*?\n'

    # Remove all binary diff blocks
    cleaned_content = re.sub(binary_diff_pattern, '', diff_content, flags=re.MULTILINE | re.DOTALL)

    return cleaned_content

def parse_diff_to_set(file_path):
    """
    Parses a diff file and converts it into a set of canonical change tuples.
    Each change is represented as (file_path, change_type, content).
    """
    changes = set()
    try:
        # Read file in binary mode first to preserve all content
        with open(file_path, 'rb') as f:
            raw_content = f.read()

        # Decode and normalize line endings (replace CRLF with LF, then strip any remaining \r)
        diff_content = raw_content.decode('utf-8').replace('\r\n', '\n').replace('\r', '\n')

        # Remove binary file diffs before passing to unidiff
        diff_content = remove_binary_diffs(diff_content)

        # Parse the normalized content
        patch_set = PatchSet(diff_content)

        for patched_file in patch_set:
            # Use the target_file path for additions and source_file for removals
            # to correctly handle file creation and deletion.
            for hunk in patched_file:
                for line in hunk:
                    # Use line.value to get the raw line content without +/-
                    content = line.value
                    if line.is_added:
                        changes.add((patched_file.target_file, 'add', content))
                    elif line.is_removed:
                        changes.add((patched_file.source_file, 'remove', content))
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

    set_g = parse_diff_to_set(pr_diff_path)
    set_r = parse_diff_to_set(recipe_diff_path)

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

    # Metric Calculation
    total_expected_changes = tp + fn

    precision = 1.0 if (tp + fp) == 0 else tp / (tp + fp)
    recall = 1.0 if (tp + fn) == 0 else tp / (tp + fn)
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
