#!/usr/bin/env python3
"""
API Documentation Generator for lean-effects

This script generates comprehensive API documentation from the Lean source code.
"""

import os
import re
import json
from pathlib import Path
from typing import Dict, List, Any, Optional


class LeanDocGenerator:
    def __init__(self, src_dir: str = "src", docs_dir: str = "docs"):
        self.src_dir = Path(src_dir)
        self.docs_dir = Path(docs_dir)
        self.api_dir = self.docs_dir / "api"

    def generate_all_docs(self) -> None:
        """Generate all API documentation."""
        print("Generating API documentation...")

        # Ensure output directory exists
        self.api_dir.mkdir(parents=True, exist_ok=True)

        # Generate documentation for each module
        self.generate_core_docs()
        self.generate_stdlib_docs()
        self.generate_dsl_docs()
        self.generate_tactics_docs()

        print("API documentation generation complete!")

    def generate_core_docs(self) -> None:
        """Generate core API documentation."""
        print("Generating core API docs...")

        core_modules = [
            "Effects.lean",
            "Effects/Core/Free.lean",
            "Effects/Core/Handler.lean",
            "Effects/Core/Fusion.lean",
        ]

        for module in core_modules:
            self.generate_module_docs(module, "core")

    def generate_stdlib_docs(self) -> None:
        """Generate standard library documentation."""
        print("Generating stdlib API docs...")

        stdlib_modules = [
            "Effects/Std/State.lean",
            "Effects/Std/Reader.lean",
            "Effects/Std/Writer.lean",
            "Effects/Std/Exception.lean",
            "Effects/Std/Nondet.lean",
        ]

        for module in stdlib_modules:
            self.generate_module_docs(module, "stdlib")

    def generate_dsl_docs(self) -> None:
        """Generate DSL documentation."""
        print("Generating DSL API docs...")

        dsl_modules = ["Effects/DSL/Syntax.lean", "Effects/DSL/Elab.lean"]

        for module in dsl_modules:
            self.generate_module_docs(module, "dsl")

    def generate_tactics_docs(self) -> None:
        """Generate tactics documentation."""
        print("Generating tactics API docs...")

        tactics_modules = [
            "Effects/Tactics/EffectFuse.lean",
            "Effects/Tactics/HandlerLaws.lean",
        ]

        for module in tactics_modules:
            self.generate_module_docs(module, "tactics")

    def generate_module_docs(self, module_path: str, category: str) -> None:
        """Generate documentation for a specific module."""
        full_path = self.src_dir / module_path

        if not full_path.exists():
            print(f"Warning: Module {module_path} not found")
            return

        # Parse the module
        module_info = self.parse_module(full_path)

        # Generate markdown documentation
        markdown = self.generate_markdown(module_info, category)

        # Write to file
        output_file = self.api_dir / f"{category}_{Path(module_path).stem}.md"
        output_file.write_text(markdown)

        print(f"Generated docs for {module_path}")

    def parse_module(self, file_path: Path) -> Dict[str, Any]:
        """Parse a Lean module and extract documentation information."""
        content = file_path.read_text()

        module_info = {
            "name": file_path.stem,
            "path": str(file_path),
            "definitions": [],
            "theorems": [],
            "classes": [],
            "instances": [],
            "namespaces": [],
            "imports": [],
        }

        # Extract imports
        import_pattern = r"import\s+([^\s\n]+)"
        module_info["imports"] = re.findall(import_pattern, content)

        # Extract definitions
        def_pattern = r"def\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*[:\s]*([^:=\n]+)"
        for match in re.finditer(def_pattern, content):
            module_info["definitions"].append(
                {
                    "name": match.group(1),
                    "type": match.group(2).strip(),
                    "line": content[: match.start()].count("\n") + 1,
                }
            )

        # Extract theorems
        theorem_pattern = r"theorem\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*[:\s]*([^:=\n]+)"
        for match in re.finditer(theorem_pattern, content):
            module_info["theorems"].append(
                {
                    "name": match.group(1),
                    "type": match.group(2).strip(),
                    "line": content[: match.start()].count("\n") + 1,
                }
            )

        # Extract classes
        class_pattern = r"class\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*[:\s]*([^:=\n]+)"
        for match in re.finditer(class_pattern, content):
            module_info["classes"].append(
                {
                    "name": match.group(1),
                    "type": match.group(2).strip(),
                    "line": content[: match.start()].count("\n") + 1,
                }
            )

        # Extract namespaces
        namespace_pattern = r"namespace\s+([a-zA-Z_][a-zA-Z0-9_]*)"
        for match in re.finditer(namespace_pattern, content):
            module_info["namespaces"].append(
                {
                    "name": match.group(1),
                    "line": content[: match.start()].count("\n") + 1,
                }
            )

        return module_info

    def generate_markdown(self, module_info: Dict[str, Any], category: str) -> str:
        """Generate markdown documentation from module information."""
        lines = []

        # Header
        lines.append(f"# {module_info['name']} API")
        lines.append("")
        lines.append(f"**Category**: {category}")
        lines.append(f"**File**: `{module_info['path']}`")
        lines.append("")

        # Imports
        if module_info["imports"]:
            lines.append("## Imports")
            lines.append("")
            for imp in module_info["imports"]:
                lines.append(f"- `{imp}`")
            lines.append("")

        # Namespaces
        if module_info["namespaces"]:
            lines.append("## Namespaces")
            lines.append("")
            for ns in module_info["namespaces"]:
                lines.append(f"- `{ns['name']}`")
            lines.append("")

        # Classes
        if module_info["classes"]:
            lines.append("## Classes")
            lines.append("")
            for cls in module_info["classes"]:
                lines.append(f"### {cls['name']}")
                lines.append("")
                lines.append(f"```lean")
                lines.append(f"class {cls['name']} : {cls['type']}")
                lines.append(f"```")
                lines.append("")

        # Definitions
        if module_info["definitions"]:
            lines.append("## Definitions")
            lines.append("")
            for defn in module_info["definitions"]:
                lines.append(f"### {defn['name']}")
                lines.append("")
                lines.append(f"```lean")
                lines.append(f"def {defn['name']} : {defn['type']}")
                lines.append(f"```")
                lines.append("")

        # Theorems
        if module_info["theorems"]:
            lines.append("## Theorems")
            lines.append("")
            for thm in module_info["theorems"]:
                lines.append(f"### {thm['name']}")
                lines.append("")
                lines.append(f"```lean")
                lines.append(f"theorem {thm['name']} : {thm['type']}")
                lines.append(f"```")
                lines.append("")

        return "\n".join(lines)


def main():
    """Main entry point."""
    generator = LeanDocGenerator()
    generator.generate_all_docs()


if __name__ == "__main__":
    main()
