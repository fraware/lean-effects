#!/usr/bin/env python3
"""
Performance gate script for lean-effects
Enforces performance thresholds and fails builds on regression
"""

import json
import sys
import argparse
from pathlib import Path
from typing import Dict, List, Optional
from dataclasses import dataclass


@dataclass
class PerformanceGate:
    """Performance gate configuration"""

    max_execution_time_ms: float = 1000.0
    max_memory_usage_mb: float = 100.0
    max_failure_rate: float = 0.0
    regression_threshold_percent: float = 10.0


class PerformanceGateChecker:
    """Performance gate checker"""

    def __init__(self, gate: PerformanceGate):
        self.gate = gate

    def load_summary(self, input_dir: str) -> Optional[Dict]:
        """Load performance summary from analysis results"""
        summary_file = Path(input_dir) / "performance-summary.json"

        if not summary_file.exists():
            print(f"Error: Performance summary not found at {summary_file}")
            return None

        try:
            with open(summary_file, "r") as f:
                return json.load(f)
        except Exception as e:
            print(f"Error loading performance summary: {e}")
            return None

    def check_gate(self, summary: Dict) -> bool:
        """Check if performance meets gate requirements"""
        print("Checking performance gate...")
        print(
            f"  Execution time: {summary.get('avg_execution_time', 0):.2f}ms (max: {self.gate.max_execution_time_ms}ms)"
        )
        print(
            f"  Memory usage: {summary.get('memory_usage', 0):.2f}MB (max: {self.gate.max_memory_usage_mb}MB)"
        )
        print(
            f"  Failed benchmarks: {summary.get('failed_benchmarks', 0)}/{summary.get('total_benchmarks', 0)}"
        )
        print(f"  Regression detected: {summary.get('regression_detected', False)}")

        # Check execution time
        if summary.get("avg_execution_time", 0) > self.gate.max_execution_time_ms:
            print(f"  ❌ FAIL: Execution time exceeds threshold")
            return False

        # Check memory usage
        if summary.get("memory_usage", 0) > self.gate.max_memory_usage_mb:
            print(f"  ❌ FAIL: Memory usage exceeds threshold")
            return False

        # Check failure rate
        total_benchmarks = summary.get("total_benchmarks", 0)
        failed_benchmarks = summary.get("failed_benchmarks", 0)
        if total_benchmarks > 0:
            failure_rate = failed_benchmarks / total_benchmarks
            if failure_rate > self.gate.max_failure_rate:
                print(
                    f"  ❌ FAIL: Failure rate {failure_rate:.1%} exceeds threshold {self.gate.max_failure_rate:.1%}"
                )
                return False

        # Check for regression
        if summary.get("regression_detected", False):
            print(f"  ❌ FAIL: Performance regression detected")
            return False

        print("  ✅ PASS: All performance gates passed")
        return True

    def print_recommendations(self, summary: Dict) -> None:
        """Print performance recommendations"""
        recommendations = summary.get("recommendations", [])
        if recommendations:
            print("\nPerformance Recommendations:")
            for i, rec in enumerate(recommendations, 1):
                print(f"  {i}. {rec}")


def main():
    parser = argparse.ArgumentParser(
        description="Check performance gate for lean-effects"
    )
    parser.add_argument(
        "--input-dir",
        required=True,
        help="Input directory containing performance analysis results",
    )
    parser.add_argument(
        "--threshold", type=float, default=10.0, help="Regression threshold percentage"
    )
    parser.add_argument(
        "--max-execution-time",
        type=float,
        default=1000.0,
        help="Maximum execution time in milliseconds",
    )
    parser.add_argument(
        "--max-memory-usage",
        type=float,
        default=100.0,
        help="Maximum memory usage in MB",
    )
    parser.add_argument(
        "--max-failure-rate",
        type=float,
        default=0.0,
        help="Maximum failure rate (0.0-1.0)",
    )

    args = parser.parse_args()

    # Create performance gate
    gate = PerformanceGate(
        max_execution_time_ms=args.max_execution_time,
        max_memory_usage_mb=args.max_memory_usage,
        max_failure_rate=args.max_failure_rate,
        regression_threshold_percent=args.threshold,
    )

    # Create checker
    checker = PerformanceGateChecker(gate)

    # Load performance summary
    summary = checker.load_summary(args.input_dir)
    if summary is None:
        sys.exit(1)

    # Check gate
    if checker.check_gate(summary):
        checker.print_recommendations(summary)
        sys.exit(0)
    else:
        checker.print_recommendations(summary)
        print("\n❌ Performance gate failed. Build will be rejected.")
        sys.exit(1)


if __name__ == "__main__":
    main()
