#!/usr/bin/env python3
"""
Performance analysis script for lean-effects
Analyzes benchmark results and detects performance regressions
"""

import json
import os
import sys
import argparse
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from pathlib import Path
from typing import Dict, List, Optional, Tuple
from dataclasses import dataclass
import statistics


@dataclass
class PerformanceThresholds:
    """Performance thresholds for different metrics"""

    execution_time_ms: float = 1000.0
    memory_usage_mb: float = 100.0
    regression_threshold_percent: float = 10.0
    max_failed_benchmarks: int = 0


@dataclass
class BenchmarkResult:
    """Individual benchmark result"""

    suite: str
    name: str
    execution_time: float
    memory_usage: int
    success: bool
    error: Optional[str] = None
    timestamp: str = ""
    lean_version: str = ""
    platform: str = ""


@dataclass
class PerformanceSummary:
    """Performance analysis summary"""

    status: str
    avg_execution_time: float
    memory_usage: float
    regression_detected: bool
    failed_benchmarks: int
    total_benchmarks: int
    recommendations: List[str]


class PerformanceAnalyzer:
    """Main performance analyzer class"""

    def __init__(self, thresholds: PerformanceThresholds):
        self.thresholds = thresholds
        self.results: List[BenchmarkResult] = []
        self.baseline_results: List[BenchmarkResult] = []

    def load_results(self, input_dir: str) -> None:
        """Load benchmark results from directory"""
        input_path = Path(input_dir)

        if not input_path.exists():
            raise FileNotFoundError(f"Input directory {input_dir} does not exist")

        # Load current results
        for json_file in input_path.glob("**/*.json"):
            if "baseline" not in json_file.name:
                self._load_json_file(json_file)

        # Load baseline results if available
        baseline_file = input_path / "baseline.json"
        if baseline_file.exists():
            self._load_baseline_file(baseline_file)

    def _load_json_file(self, json_file: Path) -> None:
        """Load results from a single JSON file"""
        try:
            with open(json_file, "r") as f:
                data = json.load(f)

            if isinstance(data, list):
                for item in data:
                    if isinstance(item, dict) and "metrics" in item:
                        result = BenchmarkResult(
                            suite=item.get("suite", "unknown"),
                            name=item.get("name", "unknown"),
                            execution_time=item["metrics"].get("executionTime", 0.0),
                            memory_usage=item["metrics"].get("memoryUsage", 0),
                            success=item.get("success", False),
                            error=item.get("error"),
                            timestamp=item["metrics"].get("timestamp", ""),
                            lean_version=item["metrics"].get("leanVersion", ""),
                            platform=item["metrics"].get("platform", ""),
                        )
                        self.results.append(result)
        except Exception as e:
            print(f"Warning: Could not load {json_file}: {e}")

    def _load_baseline_file(self, baseline_file: Path) -> None:
        """Load baseline results for comparison"""
        try:
            with open(baseline_file, "r") as f:
                data = json.load(f)

            if isinstance(data, list):
                for item in data:
                    if isinstance(item, dict) and "metrics" in item:
                        result = BenchmarkResult(
                            suite=item.get("suite", "unknown"),
                            name=item.get("name", "unknown"),
                            execution_time=item["metrics"].get("executionTime", 0.0),
                            memory_usage=item["metrics"].get("memoryUsage", 0),
                            success=item.get("success", False),
                            error=item.get("error"),
                            timestamp=item["metrics"].get("timestamp", ""),
                            lean_version=item["metrics"].get("leanVersion", ""),
                            platform=item["metrics"].get("platform", ""),
                        )
                        self.baseline_results.append(result)
        except Exception as e:
            print(f"Warning: Could not load baseline {baseline_file}: {e}")

    def analyze_performance(self) -> PerformanceSummary:
        """Analyze performance and detect regressions"""
        if not self.results:
            return PerformanceSummary(
                status="ERROR",
                avg_execution_time=0.0,
                memory_usage=0.0,
                regression_detected=False,
                failed_benchmarks=0,
                total_benchmarks=0,
                recommendations=["No benchmark results found"],
            )

        # Calculate basic metrics
        successful_results = [r for r in self.results if r.success]
        failed_results = [r for r in self.results if not r.success]

        if not successful_results:
            return PerformanceSummary(
                status="FAILED",
                avg_execution_time=0.0,
                memory_usage=0.0,
                regression_detected=True,
                failed_benchmarks=len(failed_results),
                total_benchmarks=len(self.results),
                recommendations=["All benchmarks failed"],
            )

        avg_execution_time = statistics.mean(
            r.execution_time for r in successful_results
        )
        avg_memory_usage = statistics.mean(
            r.memory_usage for r in successful_results
        ) / (
            1024 * 1024
        )  # Convert to MB

        # Check for regressions
        regression_detected = False
        recommendations = []

        # Check execution time threshold
        if avg_execution_time > self.thresholds.execution_time_ms:
            regression_detected = True
            recommendations.append(
                f"Average execution time {avg_execution_time:.2f}ms exceeds threshold {self.thresholds.execution_time_ms}ms"
            )

        # Check memory usage threshold
        if avg_memory_usage > self.thresholds.memory_usage_mb:
            regression_detected = True
            recommendations.append(
                f"Average memory usage {avg_memory_usage:.2f}MB exceeds threshold {self.thresholds.memory_usage_mb}MB"
            )

        # Check for failed benchmarks
        if len(failed_results) > self.thresholds.max_failed_benchmarks:
            regression_detected = True
            recommendations.append(
                f"Too many failed benchmarks: {len(failed_results)} > {self.thresholds.max_failed_benchmarks}"
            )

        # Compare with baseline if available
        if self.baseline_results:
            baseline_successful = [r for r in self.baseline_results if r.success]
            if baseline_successful:
                baseline_avg_time = statistics.mean(
                    r.execution_time for r in baseline_successful
                )
                time_regression = (
                    (avg_execution_time - baseline_avg_time) / baseline_avg_time
                ) * 100

                if time_regression > self.thresholds.regression_threshold_percent:
                    regression_detected = True
                    recommendations.append(
                        f"Execution time regression: {time_regression:.2f}% increase from baseline"
                    )

        # Determine overall status
        if regression_detected:
            status = "REGRESSION"
        elif len(failed_results) > 0:
            status = "PARTIAL"
        else:
            status = "PASS"

        return PerformanceSummary(
            status=status,
            avg_execution_time=avg_execution_time,
            memory_usage=avg_memory_usage,
            regression_detected=regression_detected,
            failed_benchmarks=len(failed_results),
            total_benchmarks=len(self.results),
            recommendations=recommendations,
        )

    def generate_detailed_report(self, output_dir: str) -> None:
        """Generate detailed performance report with visualizations"""
        output_path = Path(output_dir)
        output_path.mkdir(parents=True, exist_ok=True)

        if not self.results:
            print("No results to generate report for")
            return

        # Create DataFrame for analysis
        df = pd.DataFrame(
            [
                {
                    "suite": r.suite,
                    "name": r.name,
                    "execution_time": r.execution_time,
                    "memory_usage": r.memory_usage / (1024 * 1024),  # Convert to MB
                    "success": r.success,
                    "platform": r.platform,
                    "lean_version": r.lean_version,
                }
                for r in self.results
            ]
        )

        # Generate visualizations
        self._create_execution_time_plot(df, output_path)
        self._create_memory_usage_plot(df, output_path)
        self._create_suite_comparison_plot(df, output_path)
        self._create_success_rate_plot(df, output_path)

        # Generate summary statistics
        self._generate_summary_stats(df, output_path)

        # Generate recommendations
        self._generate_recommendations(output_path)

    def _create_execution_time_plot(self, df: pd.DataFrame, output_path: Path) -> None:
        """Create execution time visualization"""
        plt.figure(figsize=(12, 8))

        successful_df = df[df["success"] == True]
        if not successful_df.empty:
            sns.boxplot(data=successful_df, x="suite", y="execution_time")
            plt.title("Execution Time by Suite")
            plt.xlabel("Benchmark Suite")
            plt.ylabel("Execution Time (ms)")
            plt.xticks(rotation=45)
            plt.tight_layout()
            plt.savefig(
                output_path / "execution_time_by_suite.png",
                dpi=300,
                bbox_inches="tight",
            )
            plt.close()

    def _create_memory_usage_plot(self, df: pd.DataFrame, output_path: Path) -> None:
        """Create memory usage visualization"""
        plt.figure(figsize=(12, 8))

        successful_df = df[df["success"] == True]
        if not successful_df.empty:
            sns.boxplot(data=successful_df, x="suite", y="memory_usage")
            plt.title("Memory Usage by Suite")
            plt.xlabel("Benchmark Suite")
            plt.ylabel("Memory Usage (MB)")
            plt.xticks(rotation=45)
            plt.tight_layout()
            plt.savefig(
                output_path / "memory_usage_by_suite.png", dpi=300, bbox_inches="tight"
            )
            plt.close()

    def _create_suite_comparison_plot(
        self, df: pd.DataFrame, output_path: Path
    ) -> None:
        """Create suite comparison visualization"""
        plt.figure(figsize=(15, 10))

        successful_df = df[df["success"] == True]
        if not successful_df.empty:
            # Create subplots
            fig, axes = plt.subplots(2, 2, figsize=(15, 10))

            # Execution time by suite
            sns.boxplot(
                data=successful_df, x="suite", y="execution_time", ax=axes[0, 0]
            )
            axes[0, 0].set_title("Execution Time by Suite")
            axes[0, 0].set_xlabel("Suite")
            axes[0, 0].set_ylabel("Time (ms)")
            axes[0, 0].tick_params(axis="x", rotation=45)

            # Memory usage by suite
            sns.boxplot(data=successful_df, x="suite", y="memory_usage", ax=axes[0, 1])
            axes[0, 1].set_title("Memory Usage by Suite")
            axes[0, 1].set_xlabel("Suite")
            axes[0, 1].set_ylabel("Memory (MB)")
            axes[0, 1].tick_params(axis="x", rotation=45)

            # Success rate by suite
            success_rate = df.groupby("suite")["success"].mean()
            success_rate.plot(kind="bar", ax=axes[1, 0])
            axes[1, 0].set_title("Success Rate by Suite")
            axes[1, 0].set_xlabel("Suite")
            axes[1, 0].set_ylabel("Success Rate")
            axes[1, 0].tick_params(axis="x", rotation=45)

            # Platform comparison
            if "platform" in successful_df.columns:
                sns.boxplot(
                    data=successful_df, x="platform", y="execution_time", ax=axes[1, 1]
                )
                axes[1, 1].set_title("Execution Time by Platform")
                axes[1, 1].set_xlabel("Platform")
                axes[1, 1].set_ylabel("Time (ms)")
                axes[1, 1].tick_params(axis="x", rotation=45)

            plt.tight_layout()
            plt.savefig(
                output_path / "suite_comparison.png", dpi=300, bbox_inches="tight"
            )
            plt.close()

    def _create_success_rate_plot(self, df: pd.DataFrame, output_path: Path) -> None:
        """Create success rate visualization"""
        plt.figure(figsize=(10, 6))

        success_rate = df.groupby("suite")["success"].mean()
        success_rate.plot(kind="bar")
        plt.title("Success Rate by Suite")
        plt.xlabel("Benchmark Suite")
        plt.ylabel("Success Rate")
        plt.xticks(rotation=45)
        plt.tight_layout()
        plt.savefig(output_path / "success_rate.png", dpi=300, bbox_inches="tight")
        plt.close()

    def _generate_summary_stats(self, df: pd.DataFrame, output_path: Path) -> None:
        """Generate summary statistics"""
        stats = {
            "total_benchmarks": len(df),
            "successful_benchmarks": len(df[df["success"] == True]),
            "failed_benchmarks": len(df[df["success"] == False]),
            "success_rate": (
                len(df[df["success"] == True]) / len(df) if len(df) > 0 else 0
            ),
            "avg_execution_time": (
                df[df["success"] == True]["execution_time"].mean()
                if len(df[df["success"] == True]) > 0
                else 0
            ),
            "avg_memory_usage": (
                df[df["success"] == True]["memory_usage"].mean()
                if len(df[df["success"] == True]) > 0
                else 0
            ),
            "suites": df["suite"].unique().tolist(),
            "platforms": (
                df["platform"].unique().tolist() if "platform" in df.columns else []
            ),
            "lean_versions": (
                df["lean_version"].unique().tolist()
                if "lean_version" in df.columns
                else []
            ),
        }

        with open(output_path / "summary_stats.json", "w") as f:
            json.dump(stats, f, indent=2)

    def _generate_recommendations(self, output_path: Path) -> None:
        """Generate performance recommendations"""
        recommendations = []

        if not self.results:
            recommendations.append("No benchmark results available for analysis")
            return

        successful_results = [r for r in self.results if r.success]
        failed_results = [r for r in self.results if not r.success]

        # Check execution time
        if successful_results:
            avg_time = statistics.mean(r.execution_time for r in successful_results)
            if avg_time > self.thresholds.execution_time_ms:
                recommendations.append(
                    f"Consider optimizing slow operations (avg: {avg_time:.2f}ms)"
                )

        # Check memory usage
        if successful_results:
            avg_memory = statistics.mean(r.memory_usage for r in successful_results) / (
                1024 * 1024
            )
            if avg_memory > self.thresholds.memory_usage_mb:
                recommendations.append(
                    f"Consider reducing memory usage (avg: {avg_memory:.2f}MB)"
                )

        # Check failure rate
        failure_rate = len(failed_results) / len(self.results)
        if failure_rate > 0.1:  # 10% failure rate
            recommendations.append(f"High failure rate detected: {failure_rate:.1%}")

        # Suite-specific recommendations
        suite_stats = {}
        for result in successful_results:
            if result.suite not in suite_stats:
                suite_stats[result.suite] = []
            suite_stats[result.suite].append(result.execution_time)

        for suite, times in suite_stats.items():
            if times:
                avg_time = statistics.mean(times)
                if avg_time > self.thresholds.execution_time_ms:
                    recommendations.append(
                        f"Optimize {suite} suite (avg: {avg_time:.2f}ms)"
                    )

        with open(output_path / "recommendations.txt", "w") as f:
            f.write("Performance Recommendations\n")
            f.write("=" * 30 + "\n\n")
            for i, rec in enumerate(recommendations, 1):
                f.write(f"{i}. {rec}\n")

    def save_summary(self, output_dir: str) -> None:
        """Save performance summary for CI/CD integration"""
        summary = self.analyze_performance()

        summary_data = {
            "status": summary.status,
            "avg_execution_time": summary.avg_execution_time,
            "memory_usage": summary.memory_usage,
            "regression_detected": summary.regression_detected,
            "failed_benchmarks": summary.failed_benchmarks,
            "total_benchmarks": summary.total_benchmarks,
            "recommendations": summary.recommendations,
            "timestamp": pd.Timestamp.now().isoformat(),
        }

        output_path = Path(output_dir)
        output_path.mkdir(parents=True, exist_ok=True)

        with open(output_path / "performance-summary.json", "w") as f:
            json.dump(summary_data, f, indent=2)


def main():
    parser = argparse.ArgumentParser(
        description="Analyze lean-effects performance benchmarks"
    )
    parser.add_argument(
        "--input-dir",
        required=True,
        help="Input directory containing benchmark results",
    )
    parser.add_argument(
        "--output-dir", required=True, help="Output directory for analysis results"
    )
    parser.add_argument(
        "--threshold", type=float, default=10.0, help="Regression threshold percentage"
    )
    parser.add_argument("--baseline", action="store_true", help="Set as new baseline")

    args = parser.parse_args()

    # Set up thresholds
    thresholds = PerformanceThresholds(regression_threshold_percent=args.threshold)

    # Create analyzer
    analyzer = PerformanceAnalyzer(thresholds)

    try:
        # Load results
        analyzer.load_results(args.input_dir)

        # Analyze performance
        summary = analyzer.analyze_performance()

        # Generate detailed report
        analyzer.generate_detailed_report(args.output_dir)

        # Save summary
        analyzer.save_summary(args.output_dir)

        # Print summary
        print("Performance Analysis Summary")
        print("=" * 30)
        print(f"Status: {summary.status}")
        print(f"Average execution time: {summary.avg_execution_time:.2f}ms")
        print(f"Memory usage: {summary.memory_usage:.2f}MB")
        print(f"Regression detected: {summary.regression_detected}")
        print(
            f"Failed benchmarks: {summary.failed_benchmarks}/{summary.total_benchmarks}"
        )

        if summary.recommendations:
            print("\nRecommendations:")
            for rec in summary.recommendations:
                print(f"  - {rec}")

        # Exit with error code if regression detected
        if summary.regression_detected:
            sys.exit(1)
        else:
            sys.exit(0)

    except Exception as e:
        print(f"Error during performance analysis: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
