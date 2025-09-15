#!/usr/bin/env python3
"""
Documentation Validation Script for lean-effects

This script validates documentation links, examples, and completeness.
"""

import os
import re
import subprocess
from pathlib import Path
from typing import List, Dict, Set, Tuple


class DocValidator:
    def __init__(self, docs_dir: str = "docs", src_dir: str = "src"):
        self.docs_dir = Path(docs_dir)
        self.src_dir = Path(src_dir)
        self.errors: List[str] = []
        self.warnings: List[str] = []

    def validate_all(self) -> bool:
        """Validate all documentation."""
        print("Validating documentation...")

        self.validate_links()
        self.validate_examples()
        self.validate_completeness()
        self.validate_syntax()

        if self.errors:
            print(f"\n❌ Found {len(self.errors)} errors:")
            for error in self.errors:
                print(f"  - {error}")

        if self.warnings:
            print(f"\n⚠️  Found {len(self.warnings)} warnings:")
            for warning in self.warnings:
                print(f"  - {warning}")

        if not self.errors and not self.warnings:
            print("\n✅ All documentation validation passed!")
            return True

        return len(self.errors) == 0

    def validate_links(self) -> None:
        """Validate internal and external links."""
        print("Validating links...")

        # Find all markdown files
        md_files = list(self.docs_dir.rglob("*.md"))

        for md_file in md_files:
            self.validate_file_links(md_file)

    def validate_file_links(self, file_path: Path) -> None:
        """Validate links in a specific file."""
        content = file_path.read_text()

        # Find all markdown links
        link_pattern = r"\[([^\]]+)\]\(([^)]+)\)"
        for match in re.finditer(link_pattern, content):
            link_text = match.group(1)
            link_url = match.group(2)

            if link_url.startswith("http"):
                # External link - just check if it's well-formed
                if not self.is_valid_url(link_url):
                    self.errors.append(f"Invalid URL in {file_path}: {link_url}")
            elif link_url.startswith("#"):
                # Anchor link - check if target exists
                if not self.anchor_exists(file_path, link_url[1:]):
                    self.warnings.append(f"Missing anchor in {file_path}: {link_url}")
            elif link_url.endswith(".md"):
                # Internal markdown link
                target_path = self.resolve_internal_link(file_path, link_url)
                if not target_path.exists():
                    self.errors.append(f"Missing file in {file_path}: {link_url}")
            else:
                # Other internal link
                target_path = self.resolve_internal_link(file_path, link_url)
                if not target_path.exists():
                    self.warnings.append(f"Missing file in {file_path}: {link_url}")

    def validate_examples(self) -> None:
        """Validate code examples."""
        print("Validating examples...")

        # Find all markdown files
        md_files = list(self.docs_dir.rglob("*.md"))

        for md_file in md_files:
            self.validate_file_examples(md_file)

    def validate_file_examples(self, file_path: Path) -> None:
        """Validate code examples in a specific file."""
        content = file_path.read_text()

        # Find all code blocks
        code_block_pattern = r"```lean\n(.*?)\n```"
        for match in re.finditer(code_block_pattern, content, re.DOTALL):
            code = match.group(1)

            # Check for common issues
            if "sorry" in code:
                self.warnings.append(f"Code block contains 'sorry' in {file_path}")

            if "TODO" in code or "FIXME" in code:
                self.warnings.append(f"Code block contains TODO/FIXME in {file_path}")

            # Check for syntax issues
            if not self.is_valid_lean_syntax(code):
                self.warnings.append(f"Potential syntax issue in {file_path}")

    def validate_completeness(self) -> None:
        """Validate documentation completeness."""
        print("Validating completeness...")

        # Check for required files
        required_files = [
            "README.md",
            "reference/dsl-reference.md",
            "api/core.md",
            "cookbook/common-patterns.md",
        ]

        for file_path in required_files:
            full_path = self.docs_dir / file_path
            if not full_path.exists():
                self.errors.append(f"Missing required file: {file_path}")

        # Check for required sections in main README
        readme_path = self.docs_dir / "README.md"
        if readme_path.exists():
            content = readme_path.read_text()
            required_sections = [
                "Quick Start",
                "Core Concepts",
                "Standard Library",
                "API Reference",
            ]

            for section in required_sections:
                if section not in content:
                    self.warnings.append(f"Missing section in README: {section}")

    def validate_syntax(self) -> None:
        """Validate markdown syntax."""
        print("Validating markdown syntax...")

        # Find all markdown files
        md_files = list(self.docs_dir.rglob("*.md"))

        for md_file in md_files:
            self.validate_file_syntax(md_file)

    def validate_file_syntax(self, file_path: Path) -> None:
        """Validate markdown syntax in a specific file."""
        content = file_path.read_text()

        # Check for common markdown issues
        lines = content.split("\n")

        for i, line in enumerate(lines, 1):
            # Check for unclosed code blocks
            if line.startswith("```") and not line.endswith("```"):
                # This is a code block start
                pass

            # Check for malformed headers
            if line.startswith("#"):
                if not re.match(r"^#{1,6}\s+", line):
                    self.warnings.append(f"Malformed header in {file_path}:{i}")

            # Check for malformed links
            if "](" in line and not re.search(r"\[[^\]]+\]\([^)]+\)", line):
                self.warnings.append(f"Malformed link in {file_path}:{i}")

    def is_valid_url(self, url: str) -> bool:
        """Check if URL is well-formed."""
        url_pattern = r"^https?://[^\s/$.?#].[^\s]*$"
        return bool(re.match(url_pattern, url))

    def anchor_exists(self, file_path: Path, anchor: str) -> bool:
        """Check if anchor exists in file."""
        content = file_path.read_text()

        # Look for headers that could be anchors
        header_pattern = r"^#{1,6}\s+(.+)$"
        for match in re.finditer(header_pattern, content, re.MULTILINE):
            header_text = match.group(1)
            # Convert header to anchor (simplified)
            header_anchor = re.sub(r"[^\w\s-]", "", header_text.lower())
            header_anchor = re.sub(r"[-\s]+", "-", header_anchor)

            if header_anchor == anchor:
                return True

        return False

    def resolve_internal_link(self, from_file: Path, link: str) -> Path:
        """Resolve internal link to absolute path."""
        if link.startswith("/"):
            return self.docs_dir / link[1:]
        else:
            return from_file.parent / link


def main():
    """Main entry point."""
    validator = DocValidator()
    success = validator.validate_all()

    if not success:
        exit(1)


if __name__ == "__main__":
    main()
