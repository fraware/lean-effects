#!/usr/bin/env python3
"""
Generate HTML performance report for lean-effects
Creates a comprehensive performance dashboard
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
from typing import Dict, List, Optional
from datetime import datetime
import base64
import io


def generate_html_report(data: Dict, output_file: str) -> None:
    """Generate HTML performance report"""

    # Extract data
    summary = data.get("summary", {})
    recommendations = data.get("recommendations", [])
    charts = data.get("charts", [])

    # Generate HTML
    html = f"""
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>lean-effects Performance Report</title>
        <style>
            body {{
                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                line-height: 1.6;
                color: #333;
                max-width: 1200px;
                margin: 0 auto;
                padding: 20px;
                background-color: #f5f5f5;
            }}
            .header {{
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: white;
                padding: 30px;
                border-radius: 10px;
                margin-bottom: 30px;
                text-align: center;
            }}
            .header h1 {{
                margin: 0;
                font-size: 2.5em;
                font-weight: 300;
            }}
            .header p {{
                margin: 10px 0 0 0;
                opacity: 0.9;
                font-size: 1.1em;
            }}
            .summary {{
                display: grid;
                grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
                gap: 20px;
                margin-bottom: 30px;
            }}
            .summary-card {{
                background: white;
                padding: 25px;
                border-radius: 10px;
                box-shadow: 0 2px 10px rgba(0,0,0,0.1);
                text-align: center;
            }}
            .summary-card h3 {{
                margin: 0 0 10px 0;
                color: #666;
                font-size: 0.9em;
                text-transform: uppercase;
                letter-spacing: 1px;
            }}
            .summary-card .value {{
                font-size: 2.5em;
                font-weight: bold;
                margin: 0;
            }}
            .summary-card .status {{
                font-size: 1.2em;
                font-weight: bold;
                margin: 10px 0 0 0;
            }}
            .status.pass {{
                color: #27ae60;
            }}
            .status.fail {{
                color: #e74c3c;
            }}
            .status.warning {{
                color: #f39c12;
            }}
            .charts {{
                background: white;
                padding: 30px;
                border-radius: 10px;
                box-shadow: 0 2px 10px rgba(0,0,0,0.1);
                margin-bottom: 30px;
            }}
            .charts h2 {{
                margin: 0 0 20px 0;
                color: #333;
                border-bottom: 2px solid #667eea;
                padding-bottom: 10px;
            }}
            .chart-container {{
                margin: 20px 0;
                text-align: center;
            }}
            .chart-container img {{
                max-width: 100%;
                height: auto;
                border-radius: 5px;
                box-shadow: 0 2px 5px rgba(0,0,0,0.1);
            }}
            .recommendations {{
                background: white;
                padding: 30px;
                border-radius: 10px;
                box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            }}
            .recommendations h2 {{
                margin: 0 0 20px 0;
                color: #333;
                border-bottom: 2px solid #667eea;
                padding-bottom: 10px;
            }}
            .recommendation {{
                background: #f8f9fa;
                padding: 15px;
                margin: 10px 0;
                border-left: 4px solid #667eea;
                border-radius: 0 5px 5px 0;
            }}
            .recommendation:before {{
                content: "💡 ";
                font-size: 1.2em;
            }}
            .footer {{
                text-align: center;
                margin-top: 40px;
                padding: 20px;
                color: #666;
                border-top: 1px solid #ddd;
            }}
            .timestamp {{
                font-size: 0.9em;
                color: #999;
            }}
        </style>
    </head>
    <body>
        <div class="header">
            <h1>lean-effects Performance Report</h1>
            <p>Comprehensive performance analysis and monitoring dashboard</p>
        </div>
        
        <div class="summary">
            <div class="summary-card">
                <h3>Overall Status</h3>
                <div class="value status {summary.get('status', 'unknown').lower()}">{summary.get('status', 'Unknown')}</div>
            </div>
            <div class="summary-card">
                <h3>Average Execution Time</h3>
                <div class="value">{summary.get('avg_execution_time', 0):.2f}ms</div>
            </div>
            <div class="summary-card">
                <h3>Memory Usage</h3>
                <div class="value">{summary.get('memory_usage', 0):.2f}MB</div>
            </div>
            <div class="summary-card">
                <h3>Success Rate</h3>
                <div class="value">{summary.get('success_rate', 0):.1%}</div>
            </div>
            <div class="summary-card">
                <h3>Total Benchmarks</h3>
                <div class="value">{summary.get('total_benchmarks', 0)}</div>
            </div>
            <div class="summary-card">
                <h3>Failed Benchmarks</h3>
                <div class="value">{summary.get('failed_benchmarks', 0)}</div>
            </div>
        </div>
        
        <div class="charts">
            <h2>Performance Charts</h2>
            {generate_chart_html(charts)}
        </div>
        
        <div class="recommendations">
            <h2>Recommendations</h2>
            {generate_recommendations_html(recommendations)}
        </div>
        
        <div class="footer">
            <p>Generated by lean-effects Performance Monitor</p>
            <p class="timestamp">Report generated on {datetime.now().strftime('%Y-%m-%d %H:%M:%S UTC')}</p>
        </div>
    </body>
    </html>
    """

    # Write HTML file
    with open(output_file, "w") as f:
        f.write(html)


def generate_chart_html(charts: List[Dict]) -> str:
    """Generate HTML for charts"""
    if not charts:
        return "<p>No chart data available</p>"

    html = ""
    for chart in charts:
        if "image" in chart:
            html += f"""
            <div class="chart-container">
                <h3>{chart.get('title', 'Chart')}</h3>
                <img src="data:image/png;base64,{chart['image']}" alt="{chart.get('title', 'Chart')}">
            </div>
            """
        else:
            html += f"""
            <div class="chart-container">
                <h3>{chart.get('title', 'Chart')}</h3>
                <p>Chart data: {chart.get('data', 'No data')}</p>
            </div>
            """

    return html


def generate_recommendations_html(recommendations: List[str]) -> str:
    """Generate HTML for recommendations"""
    if not recommendations:
        return "<p>No recommendations available</p>"

    html = ""
    for rec in recommendations:
        html += f'<div class="recommendation">{rec}</div>'

    return html


def load_analysis_data(input_dir: str) -> Dict:
    """Load analysis data from directory"""
    input_path = Path(input_dir)

    # Load summary
    summary_file = input_path / "performance-summary.json"
    summary = {}
    if summary_file.exists():
        with open(summary_file, "r") as f:
            summary = json.load(f)

    # Load recommendations
    recommendations_file = input_path / "recommendations.txt"
    recommendations = []
    if recommendations_file.exists():
        with open(recommendations_file, "r") as f:
            recommendations = [
                line.strip() for line in f if line.strip() and not line.startswith("=")
            ]

    # Load charts
    charts = []
    for chart_file in input_path.glob("*.png"):
        try:
            with open(chart_file, "rb") as f:
                image_data = base64.b64encode(f.read()).decode("utf-8")
                charts.append(
                    {
                        "title": chart_file.stem.replace("_", " ").title(),
                        "image": image_data,
                    }
                )
        except Exception as e:
            print(f"Warning: Could not load chart {chart_file}: {e}")

    return {"summary": summary, "recommendations": recommendations, "charts": charts}


def main():
    parser = argparse.ArgumentParser(
        description="Generate HTML performance report for lean-effects"
    )
    parser.add_argument(
        "--input-dir", required=True, help="Input directory containing analysis results"
    )
    parser.add_argument(
        "--output", default="performance-report.html", help="Output HTML file"
    )

    args = parser.parse_args()

    try:
        # Load analysis data
        data = load_analysis_data(args.input_dir)

        # Generate HTML report
        generate_html_report(data, args.output)

        print(f"Performance report generated: {args.output}")

    except Exception as e:
        print(f"Error generating performance report: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
