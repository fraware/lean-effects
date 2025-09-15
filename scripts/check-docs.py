#!/usr/bin/env python3
"""
Documentation Completeness Checker for lean-effects

This script checks for documentation completeness and generates reports.
"""

import os
import re
from pathlib import Path
from typing import List, Dict, Set, Tuple


class DocChecker:
    def __init__(self, src_dir: str = "src", docs_dir: str = "docs"):
        self.src_dir = Path(src_dir)
        self.docs_dir = Path(docs_dir)
        self.src_files: Set[Path] = set()
        self.docs_files: Set[Path] = set()
        self.missing_docs: List[Path] = []
        self.outdated_docs: List[Path] = []

    def check_completeness(self, strict: bool = False) -> bool:
        """Check documentation completeness."""
        print("Checking documentation completeness...")

        # Find all source files
        self.find_source_files()

        # Find all documentation files
        self.find_documentation_files()

        # Check for missing documentation
        self.check_missing_documentation()

        # Check for outdated documentation
        self.check_outdated_documentation()

        # Generate report
        self.generate_report(strict)

        return len(self.missing_docs) == 0 and len(self.outdated_docs) == 0

    def find_source_files(self) -> None:
        """Find all Lean source files."""
        for file_path in self.src_dir.rglob("*.lean"):
            if not file_path.name.startswith("."):
                self.src_files.add(file_path)

        print(f"Found {len(self.src_files)} source files")

    def find_documentation_files(self) -> None:
        """Find all documentation files."""
        for file_path in self.docs_dir.rglob("*.md"):
            if not file_path.name.startswith("."):
                self.docs_files.add(file_path)

        print(f"Found {len(self.docs_files)} documentation files")

    def check_missing_documentation(self) -> None:
        """Check for missing documentation."""
        print("Checking for missing documentation...")

        # Map source files to expected documentation
        for src_file in self.src_files:
            expected_doc = self.get_expected_doc_path(src_file)

            if not expected_doc.exists():
                self.missing_docs.append(src_file)

    def check_outdated_documentation(self) -> None:
        """Check for outdated documentation."""
        print("Checking for outdated documentation...")

        # Check if documentation is older than source files
        for doc_file in self.docs_files:
            corresponding_src = self.get_corresponding_src_path(doc_file)

            if corresponding_src and corresponding_src.exists():
                if doc_file.stat().st_mtime < corresponding_src.stat().st_mtime:
                    self.outdated_docs.append(doc_file)

    def get_expected_doc_path(self, src_file: Path) -> Path:
        """Get expected documentation path for source file."""
        # Convert src/Effects/Std/State.lean to docs/api/state.md
        relative_path = src_file.relative_to(self.src_dir)

        # Remove .lean extension
        doc_name = relative_path.stem

        # Convert to lowercase and replace slashes with underscores
        doc_name = str(relative_path).replace("/", "_").replace(".lean", "").lower()

        # Map to appropriate documentation directory
        if "std" in str(relative_path):
            return self.docs_dir / "api" / f"{doc_name}.md"
        elif "dsl" in str(relative_path):
            return self.docs_dir / "api" / f"{doc_name}.md"
        elif "tactics" in str(relative_path):
            return self.docs_dir / "api" / f"{doc_name}.md"
        else:
            return self.docs_dir / "api" / f"{doc_name}.md"

    def get_corresponding_src_path(self, doc_file: Path) -> Path:
        """Get corresponding source path for documentation file."""
        # Convert docs/api/state.md to src/Effects/Std/State.lean
        relative_path = doc_file.relative_to(self.docs_dir)

        if relative_path.parts[0] == "api":
            # Map api files to std files
            doc_name = relative_path.stem

            # Convert snake_case to PascalCase
            src_name = "".join(word.capitalize() for word in doc_name.split("_"))

            # Try to find in std directory
            std_path = self.src_dir / "Effects" / "Std" / f"{src_name}.lean"
            if std_path.exists():
                return std_path

            # Try other directories
            for subdir in ["Core", "DSL", "Tactics"]:
                subdir_path = self.src_dir / "Effects" / subdir / f"{src_name}.lean"
                if subdir_path.exists():
                    return subdir_path

        return None

    def generate_report(self, strict: bool) -> None:
        """Generate completeness report."""
        print("\n" + "=" * 50)
        print("DOCUMENTATION COMPLETENESS REPORT")
        print("=" * 50)

        if self.missing_docs:
            print(f"\n❌ Missing documentation for {len(self.missing_docs)} files:")
            for src_file in sorted(self.missing_docs):
                expected_doc = self.get_expected_doc_path(src_file)
                print(f"  - {src_file} → {expected_doc}")

        if self.outdated_docs:
            print(f"\n⚠️  Outdated documentation for {len(self.outdated_docs)} files:")
            for doc_file in sorted(self.outdated_docs):
                print(f"  - {doc_file}")

        if not self.missing_docs and not self.outdated_docs:
            print("\n✅ All documentation is complete and up-to-date!")

        # Generate summary
        total_src = len(self.src_files)
        documented = total_src - len(self.missing_docs)
        completeness = (documented / total_src) * 100 if total_src > 0 else 0

        print(f"\n📊 Summary:")
        print(f"  - Source files: {total_src}")
        print(f"  - Documented: {documented}")
        print(f"  - Completeness: {completeness:.1f}%")

        if strict and (self.missing_docs or self.outdated_docs):
            print(f"\n❌ Documentation check failed in strict mode")
            return False

        return True


def main():
    """Main entry point."""
    import argparse

    parser = argparse.ArgumentParser(description="Check documentation completeness")
    parser.add_argument(
        "--strict",
        action="store_true",
        help="Fail on any missing or outdated documentation",
    )
    parser.add_argument(
        "--src-dir", default="src", help="Source directory (default: src)"
    )
    parser.add_argument(
        "--docs-dir", default="docs", help="Documentation directory (default: docs)"
    )

    args = parser.parse_args()

    checker = DocChecker(args.src_dir, args.docs_dir)
    success = checker.check_completeness(args.strict)

    if not success:
        exit(1)


if __name__ == "__main__":
    main()
