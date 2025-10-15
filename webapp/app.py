#!/usr/bin/env python3
"""
Azure Resource Discovery Web App
Deploy this to Azure App Service for web-based resource analysis
"""

from flask import Flask, render_template, request, jsonify, redirect, url_for, session
import os
import json
import logging
from datetime import datetime
import sys
import subprocess
from threading import Thread
import uuid

# Add the scripts directory to Python path
sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'scripts'))

try:
    from azure_to_aws_cost_analyzer import AzureResourceDiscovery, AWSCostEstimator
    from azure.identity import DefaultAzureCredential, ManagedIdentityCredential
except ImportError as e:
    print(f"Missing required packages: {e}")
    # For development, we'll handle this gracefully

app = Flask(__name__)
app.secret_key = os.environ.get('SECRET_KEY', 'dev-key-change-in-production')

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Global storage for analysis results (in production, use Redis or database)
analysis_results = {}

class WebAnalyzer:
    def __init__(self):
        self.subscription_id = None
        self.credential = None
        
    def initialize_azure_connection(self):
        """Initialize Azure connection using Managed Identity when deployed"""
        try:
            if os.environ.get('WEBSITE_SITE_NAME'):  # Running in Azure App Service
                logger.info("Using Managed Identity for Azure authentication")
                self.credential = ManagedIdentityCredential()
            else:  # Running locally
                logger.info("Using Default Azure Credential for local development")
                self.credential = DefaultAzureCredential()
                
            # Get subscription from environment or CLI
            self.subscription_id = os.environ.get('AZURE_SUBSCRIPTION_ID')
            if not self.subscription_id:
                try:
                    result = subprocess.run(['az', 'account', 'show', '--query', 'id', '-o', 'tsv'], 
                                          capture_output=True, text=True, check=True)
                    self.subscription_id = result.stdout.strip()
                except subprocess.CalledProcessError:
                    return False
            
            return True
        except Exception as e:
            logger.error(f"Failed to initialize Azure connection: {e}")
            return False
    
    def run_analysis(self, session_id, macc_discount=0):
        """Run the resource analysis in background"""
        try:
            analysis_results[session_id] = {
                'status': 'running',
                'progress': 'Initializing Azure connection...',
                'started_at': datetime.now().isoformat()
            }
            
            if not self.initialize_azure_connection():
                analysis_results[session_id] = {
                    'status': 'error',
                    'error': 'Failed to connect to Azure. Please ensure the app has proper permissions.',
                    'completed_at': datetime.now().isoformat()
                }
                return
            
            analysis_results[session_id]['progress'] = 'Discovering Azure resources...'
            
            # Initialize the analyzer
            analyzer = AzureResourceDiscovery(self.subscription_id)
            
            # Discover resources
            resources = analyzer.discover_resources()
            
            analysis_results[session_id]['progress'] = 'Estimating AWS costs...'
            
            # Estimate AWS costs
            estimator = AWSCostEstimator()
            aws_costs = estimator.estimate_aws_costs(resources, macc_discount)
            
            # Calculate summary
            total_azure_cost = sum(cost.get('azure_monthly_cost', 0) for cost in aws_costs.values())
            total_aws_cost = sum(cost.get('aws_monthly_cost', 0) for cost in aws_costs.values())
            
            macc_adjusted_cost = total_azure_cost * (1 - macc_discount/100) if macc_discount > 0 else total_azure_cost
            savings = macc_adjusted_cost - total_aws_cost
            savings_percent = (savings / macc_adjusted_cost * 100) if macc_adjusted_cost > 0 else 0
            
            # Store results
            analysis_results[session_id] = {
                'status': 'completed',
                'resources': resources,
                'aws_costs': aws_costs,
                'summary': {
                    'total_azure_cost': total_azure_cost,
                    'macc_discount': macc_discount,
                    'macc_adjusted_cost': macc_adjusted_cost,
                    'total_aws_cost': total_aws_cost,
                    'potential_savings': savings,
                    'savings_percent': savings_percent
                },
                'completed_at': datetime.now().isoformat()
            }
            
        except Exception as e:
            logger.error(f"Analysis failed: {e}")
            analysis_results[session_id] = {
                'status': 'error',
                'error': str(e),
                'completed_at': datetime.now().isoformat()
            }

web_analyzer = WebAnalyzer()

@app.route('/')
def index():
    """Home page"""
    return render_template('index.html')

@app.route('/analyze', methods=['POST'])
def start_analysis():
    """Start a new analysis"""
    macc_discount = float(request.form.get('macc_discount', 0))
    
    # Generate session ID
    session_id = str(uuid.uuid4())
    session['analysis_id'] = session_id
    
    # Start analysis in background
    thread = Thread(target=web_analyzer.run_analysis, args=(session_id, macc_discount))
    thread.daemon = True
    thread.start()
    
    return redirect(url_for('analysis_status', session_id=session_id))

@app.route('/status/<session_id>')
def analysis_status(session_id):
    """Show analysis status page"""
    return render_template('status.html', session_id=session_id)

@app.route('/api/status/<session_id>')
def api_status(session_id):
    """API endpoint for analysis status"""
    result = analysis_results.get(session_id, {'status': 'not_found'})
    return jsonify(result)

@app.route('/results/<session_id>')
def show_results(session_id):
    """Show analysis results"""
    result = analysis_results.get(session_id)
    if not result or result['status'] != 'completed':
        return redirect(url_for('analysis_status', session_id=session_id))
    
    return render_template('results.html', 
                         session_id=session_id, 
                         result=result)

@app.route('/api/results/<session_id>/download')
def download_results(session_id):
    """Download results as JSON"""
    result = analysis_results.get(session_id)
    if not result or result['status'] != 'completed':
        return jsonify({'error': 'Results not available'}), 404
    
    from flask import Response
    
    # Create downloadable report
    report = {
        'generated_at': datetime.now().isoformat(),
        'session_id': session_id,
        'analysis_results': result
    }
    
    response = Response(
        json.dumps(report, indent=2, default=str),
        mimetype='application/json',
        headers={'Content-Disposition': f'attachment; filename=azure_analysis_{session_id[:8]}.json'}
    )
    
    return response

@app.route('/health')
def health_check():
    """Health check endpoint for Azure App Service"""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.now().isoformat(),
        'app_service': os.environ.get('WEBSITE_SITE_NAME', 'local'),
        'version': '1.0.0'
    })

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    debug = os.environ.get('FLASK_DEBUG', 'False').lower() == 'true'
    app.run(host='0.0.0.0', port=port, debug=debug)