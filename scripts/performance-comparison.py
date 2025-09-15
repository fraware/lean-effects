#!/usr/bin/env python3
"""
Performance comparison script for lean-effects
Compares current performance with baseline and generates comparison report
"""

import json
import sys
import argparse
from pathlib import Path
from typing import Dict, List, Optional, Tuple
from dataclasses import dataclass
import statistics
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns


@dataclass
class ComparisonThresholds:
    """Comparison thresholds"""

    execution_time_percent: float = 10.0
    memory_usage_percent: float = 15.0
    failure_rate_increase: float = 5.0
    min_benchmarks: int = 5


@dataclass
class ComparisonResult:
    """Comparison result"""

    has_regression: bool
    execution_time_change: float
    memory_change: float
    failure_rate_change: float
    recommendations: List[str]
    detailed_comparison: Dict


class PerformanceComparator:
    """Performance comparator"""

    def __init__(self, thresholds: ComparisonThresholds):
        self.thresholds = thresholds

    def load_baseline(self, baseline_file: str) -> Optional[Dict]:
        """Load baseline performance data"""
        baseline_path = Path(baseline_file)

        if not baseline_path.exists():
            print(f"Warning: Baseline file {baseline_file} not found")
            return None

        try:
            with open(baseline_path, "r") as f:
                return json.load(f)
        except Exception as e:
            print(f"Error loading baseline: {e}")
            return None

    def load_current(self, current_file: str) -> Optional[Dict]:
        """Load current performance data"""
        current_path = Path(current_file)

        if not current_path.exists():
            print(f"Error: Current performance file {current_file} not found")
            return None

        try:
            with open(current_path, "r") as f:
                return json.load(f)
        except Exception as e:
            print(f"Error loading current performance: {e}")
            return None

    def extract_metrics(self, data: Dict) -> Tuple[float, float, float, int, int]:
        """Extract key metrics from performance data"""
        if isinstance(data, list):
            # Handle list of benchmark results
            successful_results = [r for r in data if r.get("success", False)]
            failed_results = [r for r in data if not r.get("success", False)]

            if not successful_results:
                return 0.0, 0.0, 1.0, 0, len(data)

            execution_times = [
                r.get("metrics", {}).get("executionTime", 0) for r in successful_results
            ]
            memory_usage = [
                r.get("metrics", {}).get("memoryUsage", 0) for r in successful_results
            ]

            avg_execution_time = (
                statistics.mean(execution_times) if execution_times else 0.0
            )
            avg_memory_usage = (
                statistics.mean(memory_usage) / (1024 * 1024) if memory_usage else 0.0
            )  # Convert to MB
            failure_rate = len(failed_results) / len(data) if data else 0.0

            return (
                avg_execution_time,
                avg_memory_usage,
                failure_rate,
                len(successful_results),
                len(data),
            )

        elif isinstance(data, dict):
            # Handle summary format
            return (
                data.get("avg_execution_time", 0.0),
                data.get("memory_usage", 0.0),
                data.get("failed_benchmarks", 0)
                / max(data.get("total_benchmarks", 1), 1),
                data.get("successful_benchmarks", 0),
                data.get("total_benchmarks", 0),
            )

        return 0.0, 0.0, 0.0, 0, 0

    def compare_performance(
        self, baseline_data: Dict, current_data: Dict
    ) -> ComparisonResult:
        """Compare performance between baseline and current"""
        baseline_metrics = self.extract_metrics(baseline_data)
        current_metrics = self.extract_metrics(current_data)

        (
            baseline_time,
            baseline_memory,
            baseline_failure_rate,
            baseline_successful,
            baseline_total,
        ) = baseline_metrics
        (
            current_time,
            current_memory,
            current_failure_rate,
            current_successful,
            current_total,
        ) = current_metrics

        # Check if we have enough data
        if current_successful < self.thresholds.min_benchmarks:
            return ComparisonResult(
                has_regression=True,
                execution_time_change=0.0,
                memory_change=0.0,
                failure_rate_change=0.0,
                recommendations=[
                    f"Insufficient successful benchmarks: {current_successful} < {self.thresholds.min_benchmarks}"
                ],
                detailed_comparison={},
            )

        # Calculate changes
        execution_time_change = 0.0
        memory_change = 0.0
        failure_rate_change = 0.0

        if baseline_time > 0:
            execution_time_change = (
                (current_time - baseline_time) / baseline_time
            ) * 100

        if baseline_memory > 0:
            memory_change = ((current_memory - baseline_memory) / baseline_memory) * 100

        failure_rate_change = current_failure_rate - baseline_failure_rate

        # Check for regressions
        execution_time_regression = (
            execution_time_change > self.thresholds.execution_time_percent
        )
        memory_regression = memory_change > self.thresholds.memory_usage_percent
        failure_rate_regression = (
            failure_rate_change > self.thresholds.failure_rate_increase / 100
        )

        has_regression = (
            execution_time_regression or memory_regression or failure_rate_regression
        )

        # Generate recommendations
        recommendations = []

        if execution_time_regression:
            recommendations.append(
                f"Execution time increased by {execution_time_change:.1f}% (threshold: {self.thresholds.execution_time_percent}%)"
            )

        if memory_regression:
            recommendations.append(
                f"Memory usage increased by {memory_change:.1f}% (threshold: {self.thresholds.memory_usage_percent}%)"
            )

        if failure_rate_regression:
            recommendations.append(
                f"Failure rate increased by {failure_rate_change:.1%} (threshold: {self.thresholds.failure_rate_increase}%)"
            )

        if not has_regression:
            recommendations.append("No significant performance regression detected")

        # Create detailed comparison
        detailed_comparison = {
            "baseline": {
                "execution_time": baseline_time,
                "memory_usage": baseline_memory,
                "failure_rate": baseline_failure_rate,
                "successful_benchmarks": baseline_successful,
                "total_benchmarks": baseline_total,
            },
            "current": {
                "execution_time": current_time,
                "memory_usage": current_memory,
                "failure_rate": current_failure_rate,
                "successful_benchmarks": current_successful,
                "total_benchmarks": current_total,
            },
            "changes": {
                "execution_time_percent": execution_time_change,
                "memory_usage_percent": memory_change,
                "failure_rate_absolute": failure_rate_change,
            },
            "regressions": {
                "execution_time": execution_time_regression,
                "memory_usage": memory_regression,
                "failure_rate": failure_rate_regression,
            },
        }

        return ComparisonResult(
            has_regression=has_regression,
            execution_time_change=execution_time_change,
            memory_change=memory_change,
            failure_rate_change=failure_rate_change,
            recommendations=recommendations,
            detailed_comparison=detailed_comparison,
        )

    def generate_comparison_report(
        self, result: ComparisonResult, output_dir: str
    ) -> None:
        """Generate detailed comparison report"""
        output_path = Path(output_dir)
        output_path.mkdir(parents=True, exist_ok=True)

        # Save detailed comparison
        with open(output_path / "performance-comparison.json", "w") as f:
            json.dump(result.detailed_comparison, f, indent=2)

        # Generate visualizations
        self._create_comparison_charts(result, output_path)

        # Generate summary report
        self._generate_summary_report(result, output_path)

    def _create_comparison_charts(
        self, result: ComparisonResult, output_path: Path
    ) -> None:
        """Create comparison charts"""
        comparison = result.detailed_comparison

        # Create comparison bar chart
        fig, axes = plt.subplots(2, 2, figsize=(15, 10))

        # Execution time comparison
        axes[0, 0].bar(
            ["Baseline", "Current"],
            [
                comparison["baseline"]["execution_time"],
                comparison["current"]["execution_time"],
            ],
        )
        axes[0, 0].set_title("Execution Time Comparison")
        axes[0, 0].set_ylabel("Time (ms)")

        # Memory usage comparison
        axes[0, 1].bar(
            ["Baseline", "Current"],
            [
                comparison["baseline"]["memory_usage"],
                comparison["current"]["memory_usage"],
            ],
        )
        axes[0, 1].set_title("Memory Usage Comparison")
        axes[0, 1].set_ylabel("Memory (MB)")

        # Failure rate comparison
        axes[1, 0].bar(
            ["Baseline", "Current"],
            [
                comparison["baseline"]["failure_rate"],
                comparison["current"]["failure_rate"],
            ],
        )
        axes[1, 0].set_title("Failure Rate Comparison")
        axes[1, 0].set_ylabel("Failure Rate")

        # Change percentages
        changes = comparison["changes"]
        axes[1, 1].bar(
            ["Execution Time", "Memory Usage", "Failure Rate"],
            [
                changes["execution_time_percent"],
                changes["memory_usage_percent"],
                changes["failure_rate_absolute"] * 100,
            ],
        )
        axes[1, 1].set_title("Performance Changes")
        axes[1, 1].set_ylabel("Change (%)")
        axes[1, 1].axhline(y=0, color="black", linestyle="-", alpha=0.3)

        plt.tight_layout()
        plt.savefig(
            output_path / "performance-comparison.png", dpi=300, bbox_inches="tight"
        )
        plt.close()

    def _generate_summary_report(
        self, result: ComparisonResult, output_path: Path
    ) -> None:
        """Generate summary report"""
        comparison = result.detailed_comparison

        report = f"""
Performance Comparison Report
============================

Overall Status: {'REGRESSION DETECTED' if result.has_regression else 'NO REGRESSION'}

Execution Time:
  Baseline: {comparison['baseline']['execution_time']:.2f}ms
  Current:  {comparison['current']['execution_time']:.2f}ms
  Change:   {result.execution_time_change:+.1f}%

Memory Usage:
  Baseline: {comparison['baseline']['memory_usage']:.2f}MB
  Current:  {comparison['current']['memory_usage']:.2f}MB
  Change:   {result.memory_change:+.1f}%

Failure Rate:
  Baseline: {comparison['baseline']['failure_rate']:.1%}
  Current:  {comparison['current']['failure_rate']:.1%}
  Change:   {result.failure_rate_change:+.1%}

Benchmark Count:
  Baseline: {comparison['baseline']['successful_benchmarks']}/{comparison['baseline']['total_benchmarks']} successful
  Current:  {comparison['current']['successful_benchmarks']}/{comparison['current']['total_benchmarks']} successful

Recommendations:
"""

        for rec in result.recommendations:
            report += f"  - {rec}\n"

        with open(output_path / "comparison-summary.txt", "w") as f:
            f.write(report)


def main():
    parser = argparse.ArgumentParser(
        description="Compare performance between baseline and current"
    )
    parser.add_argument("--baseline", required=True, help="Baseline performance file")
    parser.add_argument("--current", required=True, help="Current performance file")
    parser.add_argument(
        "--output-dir", required=True, help="Output directory for comparison results"
    )
    parser.add_argument(
        "--threshold",
        type=float,
        default=10.0,
        help="Execution time regression threshold percentage",
    )
    parser.add_argument(
        "--memory-threshold",
        type=float,
        default=15.0,
        help="Memory usage regression threshold percentage",
    )
    parser.add_argument(
        "--failure-threshold",
        type=float,
        default=5.0,
        help="Failure rate increase threshold percentage",
    )
    parser.add_argument(
        "--min-benchmarks",
        type=int,
        default=5,
        help="Minimum number of successful benchmarks required",
    )

    args = parser.parse_args()

    # Create thresholds
    thresholds = ComparisonThresholds(
        execution_time_percent=args.threshold,
        memory_usage_percent=args.memory_threshold,
        failure_rate_increase=args.failure_threshold,
        min_benchmarks=args.min_benchmarks,
    )

    # Create comparator
    comparator = PerformanceComparator(thresholds)

    # Load data
    baseline_data = comparator.load_baseline(args.baseline)
    current_data = comparator.load_current(args.current)

    if baseline_data is None or current_data is None:
        print("Error: Could not load performance data")
        sys.exit(1)

    # Compare performance
    result = comparator.compare_performance(baseline_data, current_data)

    # Generate report
    comparator.generate_comparison_report(result, args.output_dir)

    # Print summary
    print("Performance Comparison Summary")
    print("=" * 30)
    print(f"Regression detected: {result.has_regression}")
    print(f"Execution time change: {result.execution_time_change:+.1f}%")
    print(f"Memory change: {result.memory_change:+.1f}%")
    print(f"Failure rate change: {result.failure_rate_change:+.1%}")

    if result.recommendations:
        print("\nRecommendations:")
        for rec in result.recommendations:
            print(f"  - {rec}")

    # Exit with error code if regression detected
    if result.has_regression:
        print("\n❌ Performance regression detected. Build will be rejected.")
        sys.exit(1)
    else:
        print("\n✅ No significant performance regression detected.")
        sys.exit(0)


if __name__ == "__main__":
    main()
