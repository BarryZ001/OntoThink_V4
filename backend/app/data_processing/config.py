import os
from pathlib import Path

# Base directory
BASE_DIR = Path(__file__).parent.parent.parent  # Points to backend/app
# Data and log directories are in the backend directory
DATA_DIR = os.path.join(BASE_DIR, 'data')
LOG_DIR = os.path.join(BASE_DIR, 'logs')

# API Configuration
DEEPSEEK_API_KEY = "sk-b7bf1c93500b4a98a3ac65f2fc47866f"  # Replace with your actual API key
DEEPSEEK_API_BASE = "https://api.deepseek.com/v1"
MODEL_NAME = "deepseek-chat"
MAX_TOKENS = 4000
TEMPERATURE = 0.7  # Lower temperature for more focused and consistent outputs
TOP_P = 0.95
FREQUENCY_PENALTY = 0.0
PRESENCE_PENALTY = 0.0
TIMEOUT = 60  # Increased timeout for complex philosophical queries
MAX_RETRIES = 5  # Increased retries for better reliability

# File Paths
SEED_QUESTIONS_FILE = os.path.join(DATA_DIR, 'seed_questions.json')
EXPANDED_DATASET_FILE = os.path.join(DATA_DIR, 'philosophical_debates.json')
LOG_FILE = os.path.join(LOG_DIR, 'philosophy_data_generation.log')

# Processing Parameters
BATCH_SIZE = 3  # Smaller batch size to avoid rate limiting
DELAY_BETWEEN_REQUESTS = 5  # Increased delay between requests
MAX_CONCURRENT_REQUESTS = 1  # Process one question at a time

# Data Validation
MIN_QUESTIONS = 1
MIN_STANDPOINTS = 2
MIN_ARGUMENTS_PER_STANDPOINT = 2
MIN_COUNTER_QUESTIONS = 2

# Ensure directories exist
os.makedirs(DATA_DIR, exist_ok=True)
os.makedirs(LOG_DIR, exist_ok=True)
