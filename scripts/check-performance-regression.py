#!/usr/bin/env python3
"""
Performance regression detection script for lean-effects
Compares current performance with baseline and detects regressions
"""

import json
import sys
import argparse
from pathlib import Path
from typing import Dict, List, Optional, Tuple
from dataclasses import dataclass
import statistics


@dataclass
class RegressionThresholds:
    """Regression detection thresholds"""

    execution_time_percent: float = 10.0
    memory_usage_percent: float = 15.0
    failure_rate_increase: float = 5.0
    min_benchmarks: int = 5


@dataclass
class RegressionResult:
    """Regression detection result"""

    has_regression: bool
    execution_time_regression: bool
    memory_regression: bool
    failure_rate_regression: bool
    execution_time_change: float
    memory_change: float
    failure_rate_change: float
    recommendations: List[str]


class PerformanceRegressionDetector:
    """Performance regression detector"""

    def __init__(self, thresholds: RegressionThresholds):
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

    def detect_regression(
        self, baseline_data: Dict, current_data: Dict
    ) -> RegressionResult:
        """Detect performance regression"""
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
            return RegressionResult(
                has_regression=True,
                execution_time_regression=False,
                memory_regression=False,
                failure_rate_regression=False,
                execution_time_change=0.0,
                memory_change=0.0,
                failure_rate_change=0.0,
                recommendations=[
                    f"Insufficient successful benchmarks: {current_successful} < {self.thresholds.min_benchmarks}"
                ],
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

        return RegressionResult(
            has_regression=has_regression,
            execution_time_regression=execution_time_regression,
            memory_regression=memory_regression,
            failure_rate_regression=failure_rate_regression,
            execution_time_change=execution_time_change,
            memory_change=memory_change,
            failure_rate_change=failure_rate_change,
            recommendations=recommendations,
        )

    def print_comparison(self, baseline_metrics: Tuple, current_metrics: Tuple) -> None:
        """Print performance comparison"""
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

        print("Performance Comparison")
        print("=" * 30)
        print(f"Execution Time:")
        print(f"  Baseline: {baseline_time:.2f}ms")
        print(f"  Current:  {current_time:.2f}ms")
        print(
            f"  Change:   {((current_time - baseline_time) / baseline_time * 100) if baseline_time > 0 else 0:.1f}%"
        )
        print()
        print(f"Memory Usage:")
        print(f"  Baseline: {baseline_memory:.2f}MB")
        print(f"  Current:  {current_memory:.2f}MB")
        print(
            f"  Change:   {((current_memory - baseline_memory) / baseline_memory * 100) if baseline_memory > 0 else 0:.1f}%"
        )
        print()
        print(f"Failure Rate:")
        print(f"  Baseline: {baseline_failure_rate:.1%}")
        print(f"  Current:  {current_failure_rate:.1%}")
        print(f"  Change:   {(current_failure_rate - baseline_failure_rate):.1%}")
        print()
        print(f"Benchmark Count:")
        print(f"  Baseline: {baseline_successful}/{baseline_total} successful")
        print(f"  Current:  {current_successful}/{current_total} successful")


def main():
    parser = argparse.ArgumentParser(
        description="Check for performance regressions in lean-effects"
    )
    parser.add_argument("--baseline", required=True, help="Baseline performance file")
    parser.add_argument("--current", required=True, help="Current performance file")
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
    thresholds = RegressionThresholds(
        execution_time_percent=args.threshold,
        memory_usage_percent=args.memory_threshold,
        failure_rate_increase=args.failure_threshold,
        min_benchmarks=args.min_benchmarks,
    )

    # Create detector
    detector = PerformanceRegressionDetector(thresholds)

    # Load data
    baseline_data = detector.load_baseline(args.baseline)
    current_data = detector.load_current(args.current)

    if baseline_data is None or current_data is None:
        print("Error: Could not load performance data")
        sys.exit(1)

    # Print comparison
    baseline_metrics = detector.extract_metrics(baseline_data)
    current_metrics = detector.extract_metrics(current_data)
    detector.print_comparison(baseline_metrics, current_metrics)

    # Detect regression
    result = detector.detect_regression(baseline_data, current_data)

    print("\nRegression Analysis")
    print("=" * 20)
    print(f"Regression detected: {result.has_regression}")
    print(f"Execution time regression: {result.execution_time_regression}")
    print(f"Memory regression: {result.memory_regression}")
    print(f"Failure rate regression: {result.failure_rate_regression}")

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
