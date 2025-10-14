# Makefile for Azure to AWS Cost Analyzer

.PHONY: help setup test run clean install analyze check-accuracy

help:
	@echo "Azure to AWS Cost Analyzer - Available commands:"
	@echo ""
	@echo "  make analyze  - 🚀 Run the main analyzer (recommended)"
	@echo "  make setup    - Install dependencies and setup environment"
	@echo "  make test     - Run tests to verify everything works"
	@echo "  make run      - Run advanced analyzer with options"
	@echo "  make accuracy - Check AWS pricing accuracy"
	@echo "  make install  - Install Python dependencies only"
	@echo "  make clean    - Remove generated files"
	@echo "  make help     - Show this help message"
	@echo ""

analyze:
	@echo "🚀 Running the main Azure to AWS cost analyzer..."
	@chmod +x analyze.sh
	@./analyze.sh

setup:
	@echo "🚀 Setting up Azure to AWS Cost Analyzer..."
	@chmod +x scripts/setup.sh
	@./scripts/setup.sh

install:
	@echo "📦 Installing Python dependencies..."
	@pip3 install -r requirements.txt
	@echo "✅ Dependencies installed!"

test:
	@echo "🧪 Running tests..."
	@python3 examples/test_analyzer.py

run:
	@echo "🔍 Running advanced analyzer..."
	@python3 scripts/azure_to_aws_cost_analyzer.py

run-json:
	@echo "🔍 Running analyzer with JSON output..."
	@python3 scripts/azure_to_aws_cost_analyzer.py --json --output azure_aws_analysis.json
	@echo "Results saved to azure_aws_analysis.json"

run-report:
	@echo "🔍 Running analyzer and saving text report..."
	@python3 scripts/azure_to_aws_cost_analyzer.py --output azure_aws_analysis.txt
	@echo "Report saved to azure_aws_analysis.txt"

check-accuracy:
	@echo "🎯 Checking AWS pricing accuracy..."
	@python3 scripts/pricing_accuracy_check.py

clean:
	@echo "🧹 Cleaning up generated files..."
	@rm -f azure_aws_analysis_*.txt azure_aws_analysis_*.json
	@rm -f azure_analyzer.py
	@rm -rf __pycache__
	@echo "✅ Cleanup complete!"

check-prerequisites:
	@echo "🔍 Checking prerequisites..."
	@python3 --version || (echo "❌ Python 3 not found" && exit 1)
	@az --version > /dev/null || (echo "❌ Azure CLI not found" && exit 1)
	@az account show > /dev/null || (echo "❌ Not logged into Azure CLI" && exit 1)
	@echo "✅ All prerequisites met!"