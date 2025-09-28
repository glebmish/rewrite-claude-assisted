#!/usr/bin/env python3
"""
PR Diff Analysis for Recipe Precision
Compares original PR changes with OpenRewrite recipe-generated changes
to calculate precision, recall, and accuracy metrics.
"""

import argparse
import json
import os
import re
import sys
from typing import Dict, List, Set, Tuple, Optional
from urllib.parse import urlparse
import requests


class PRDiffAnalyzer:
    """Analyzes PR diffs to calculate recipe precision metrics."""

    def __init__(self, github_token: Optional[str] = None):
        """Initialize with optional GitHub token for API access."""
        self.github_token = github_token or os.getenv('GH_TOKEN') or os.getenv('GITHUB_TOKEN')
        self.session = requests.Session()
        if self.github_token:
            self.session.headers.update({'Authorization': f'token {self.github_token}'})

    def parse_pr_url(self, pr_url: str) -> Tuple[str, int]:
        """Parse GitHub PR URL to extract owner/repo and PR number."""
        # Example: https://github.com/owner/repo/pull/123
        match = re.match(r'https://github\.com/([^/]+)/([^/]+)/pull/(\d+)', pr_url)
        if not match:
            raise ValueError(f"Invalid GitHub PR URL: {pr_url}")

        owner, repo, pr_number = match.groups()
        return f"{owner}/{repo}", int(pr_number)

    def get_pr_diff(self, repo: str, pr_number: int) -> str:
        """Fetch PR diff from GitHub API."""
        url = f"https://api.github.com/repos/{repo}/pulls/{pr_number}"

        # Request diff format
        headers = {'Accept': 'application/vnd.github.v3.diff'}
        if self.github_token:
            headers['Authorization'] = f'token {self.github_token}'

        response = requests.get(url, headers=headers)
        response.raise_for_status()

        return response.text

    def parse_diff(self, diff_content: str) -> Dict[str, List[Tuple[int, str, str]]]:
        """
        Parse unified diff into structured changes.

        Returns:
            Dict mapping filename to list of (line_number, change_type, content) tuples
            where change_type is 'add' or 'del'
        """
        changes = {}
        current_file = None
        line_number = 0

        for line in diff_content.split('\n'):
            # File header: diff --git a/file b/file
            if line.startswith('diff --git'):
                continue

            # New file marker: +++ b/filename
            elif line.startswith('+++'):
                match = re.match(r'\+\+\+ b/(.+)', line)
                if match:
                    current_file = match.group(1)
                    changes[current_file] = []
                continue

            # Hunk header: @@ -start,count +start,count @@
            elif line.startswith('@@'):
                match = re.match(r'@@ -\d+(?:,\d+)? \+(\d+)(?:,\d+)? @@', line)
                if match:
                    line_number = int(match.group(1))
                continue

            # Skip file headers and other metadata
            elif line.startswith('---') or line.startswith('index ') or line.startswith('new file') or line.startswith('deleted file'):
                continue

            # Process change lines
            elif current_file is not None:
                if line.startswith('+'):
                    # Addition
                    content = line[1:]  # Remove + prefix
                    changes[current_file].append((line_number, 'add', content))
                    line_number += 1
                elif line.startswith('-'):
                    # Deletion
                    content = line[1:]  # Remove - prefix
                    changes[current_file].append((line_number, 'del', content))
                    # Don't increment line_number for deletions
                elif line.startswith(' '):
                    # Context line (unchanged)
                    line_number += 1
                elif line.strip() == '':
                    # Empty line
                    line_number += 1

        return changes

    def normalize_change(self, change: Tuple[int, str, str]) -> str:
        """
        Normalize a change for comparison.

        Creates a comparable string representation of the change.
        Format: "file:type:content" (line number excluded for flexibility)
        """
        line_num, change_type, content = change
        # Normalize whitespace and remove trailing/leading spaces
        normalized_content = ' '.join(content.split())
        return f"{change_type}:{normalized_content}"

    def get_all_changes(self, file_changes: Dict[str, List[Tuple[int, str, str]]]) -> Set[str]:
        """Convert file changes to a set of normalized change strings."""
        all_changes = set()

        for filename, changes in file_changes.items():
            for change in changes:
                normalized = self.normalize_change(change)
                # Include filename in the change identifier
                all_changes.add(f"{filename}:{normalized}")

        return all_changes

    def calculate_precision_metrics(self, original_changes: Set[str], recipe_changes: Set[str]) -> Dict[str, float]:
        """
        Calculate precision metrics comparing original and recipe changes.

        Args:
            original_changes: Set of normalized changes from original PR
            recipe_changes: Set of normalized changes from recipe PR

        Returns:
            Dictionary with precision, recall, f1_score, and accuracy metrics
        """
        # Find overlaps and differences
        exact_matches = original_changes & recipe_changes
        missing_changes = original_changes - recipe_changes
        unnecessary_changes = recipe_changes - original_changes

        # Calculate metrics
        total_original = len(original_changes)
        total_recipe = len(recipe_changes)
        total_matched = len(exact_matches)
        total_missing = len(missing_changes)
        total_unnecessary = len(unnecessary_changes)

        # Precision: What fraction of recipe changes were correct?
        precision = total_matched / total_recipe if total_recipe > 0 else 0.0

        # Recall: What fraction of original changes were captured?
        recall = total_matched / total_original if total_original > 0 else 0.0

        # F1 Score: Harmonic mean of precision and recall
        f1_score = 2 * (precision * recall) / (precision + recall) if (precision + recall) > 0 else 0.0

        # Accuracy: What fraction of all changes were correct?
        total_changes = total_matched + total_missing + total_unnecessary
        accuracy = total_matched / total_changes if total_changes > 0 else 0.0

        return {
            'precision': precision,
            'recall': recall,
            'f1_score': f1_score,
            'accuracy': accuracy,
            'exact_matches': total_matched,
            'missing_changes': total_missing,
            'unnecessary_changes': total_unnecessary,
            'total_original_changes': total_original,
            'total_recipe_changes': total_recipe
        }

    def analyze_pr_precision(self, original_pr_url: str, recipe_pr_url: str) -> Dict:
        """
        Main analysis function to compare two PRs and calculate precision metrics.

        Args:
            original_pr_url: URL of the original human-authored PR
            recipe_pr_url: URL of the recipe-generated PR

        Returns:
            Dictionary containing precision metrics and analysis details
        """
        try:
            # Parse PR URLs
            original_repo, original_pr = self.parse_pr_url(original_pr_url)
            recipe_repo, recipe_pr = self.parse_pr_url(recipe_pr_url)

            # Fetch diffs
            original_diff = self.get_pr_diff(original_repo, original_pr)
            recipe_diff = self.get_pr_diff(recipe_repo, recipe_pr)

            # Parse diffs into structured changes
            original_file_changes = self.parse_diff(original_diff)
            recipe_file_changes = self.parse_diff(recipe_diff)

            # Convert to comparable change sets
            original_changes = self.get_all_changes(original_file_changes)
            recipe_changes = self.get_all_changes(recipe_file_changes)

            # Calculate precision metrics
            metrics = self.calculate_precision_metrics(original_changes, recipe_changes)

            # Add metadata
            analysis_result = {
                'original_pr': {
                    'url': original_pr_url,
                    'repo': original_repo,
                    'number': original_pr,
                    'files_changed': len(original_file_changes),
                    'total_changes': len(original_changes)
                },
                'recipe_pr': {
                    'url': recipe_pr_url,
                    'repo': recipe_repo,
                    'number': recipe_pr,
                    'files_changed': len(recipe_file_changes),
                    'total_changes': len(recipe_changes)
                },
                'metrics': metrics,
                'status': 'success'
            }

            return analysis_result

        except Exception as e:
            return {
                'status': 'error',
                'error': str(e),
                'original_pr_url': original_pr_url,
                'recipe_pr_url': recipe_pr_url
            }


def main():
    """Command line interface for PR diff analysis."""
    parser = argparse.ArgumentParser(description='Analyze PR diff precision for OpenRewrite recipes')
    parser.add_argument('original_pr', help='URL of the original PR')
    parser.add_argument('recipe_pr', help='URL of the recipe-generated PR')
    parser.add_argument('--github-token', help='GitHub API token (or use GH_TOKEN env var)')
    parser.add_argument('--output', '-o', help='Output file for JSON results')

    args = parser.parse_args()

    # Initialize analyzer
    analyzer = PRDiffAnalyzer(github_token=args.github_token)

    # Perform analysis
    result = analyzer.analyze_pr_precision(args.original_pr, args.recipe_pr)

    # Output results
    if args.output:
        with open(args.output, 'w') as f:
            json.dump(result, f, indent=2)
    else:
        print(json.dumps(result, indent=2))

    # Exit with error code if analysis failed
    if result.get('status') != 'success':
        sys.exit(1)


if __name__ == '__main__':
    main()