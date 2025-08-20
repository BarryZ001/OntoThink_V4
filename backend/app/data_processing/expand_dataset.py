import json
import os
import time
import random
import logging
from typing import List, Dict, Any, Optional
from pathlib import Path
from tqdm import tqdm

# Import the DeepSeekAPI class and configuration
from .deepseek_api import DeepSeekAPI
from .config import (
    SEED_QUESTIONS_FILE, EXPANDED_DATASET_FILE, LOG_FILE,
    BATCH_SIZE, DELAY_BETWEEN_REQUESTS, MAX_RETRIES
)

# Set up logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(LOG_FILE, encoding='utf-8'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

class DatasetExpander:
    """A class to handle the expansion of philosophical questions into debate structures."""
    
    def __init__(self):
        """Initialize the dataset expander with the DeepSeek API client."""
        self.api = DeepSeekAPI()
        self.processed_questions = set()
        self.existing_data = []
        
        # Create necessary directories if they don't exist
        os.makedirs(os.path.dirname(EXPANDED_DATASET_FILE), exist_ok=True)
        os.makedirs(os.path.dirname(LOG_FILE), exist_ok=True)
    
    def load_seed_questions(self) -> List[Dict[str, Any]]:
        """Load seed questions from the JSON file."""
        try:
            with open(SEED_QUESTIONS_FILE, 'r', encoding='utf-8') as f:
                data = json.load(f)
                # Ensure we have a list of questions
                if isinstance(data, dict) and 'questions' in data:
                    return data['questions']
                elif isinstance(data, list):
                    return data
                else:
                    logger.error("Invalid seed questions format")
                    return []
        except (FileNotFoundError, json.JSONDecodeError) as e:
            logger.error(f"Failed to load seed questions: {e}")
            return []
    
    def load_existing_expanded_data(self) -> None:
        """Load existing expanded data to avoid reprocessing."""
        if os.path.exists(EXPANDED_DATASET_FILE):
            try:
                with open(EXPANDED_DATASET_FILE, 'r', encoding='utf-8') as f:
                    self.existing_data = json.load(f)
                    self.processed_questions = {
                        item['question'] 
                        for item in self.existing_data 
                        if 'question' in item
                    }
                logger.info(f"Loaded {len(self.existing_data)} existing expanded questions")
            except (json.JSONDecodeError, KeyError) as e:
                logger.error(f"Error loading existing expanded data: {e}")
                self.existing_data = []
    
    def save_expanded_data(self, data: List[Dict[str, Any]]) -> None:
        """Save the expanded data to a JSON file."""
        try:
            # Create a temporary file first to ensure atomic write
            temp_file = f"{EXPANDED_DATASET_FILE}.tmp"
            with open(temp_file, 'w', encoding='utf-8') as f:
                json.dump(data, f, ensure_ascii=False, indent=2, sort_keys=True)
            
            # Replace the original file
            if os.path.exists(EXPANDED_DATASET_FILE):
                os.replace(temp_file, EXPANDED_DATASET_FILE)
            else:
                os.rename(temp_file, EXPANDED_DATASET_FILE)
                
            logger.info(f"Successfully saved {len(data)} expanded questions to {EXPANDED_DATASET_FILE}")
        except Exception as e:
            logger.error(f"Failed to save expanded data: {e}")
            if os.path.exists(temp_file):
                os.remove(temp_file)
    
    def expand_question(self, question_data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """Expand a single philosophical question into a debate structure."""
        question_text = question_data.get('question', '')
        if not question_text:
            logger.warning("Skipping empty question")
            return None
            
        if question_text in self.processed_questions:
            logger.info(f"Skipping already processed question: {question_text[:50]}...")
            return None
            
        logger.info(f"Expanding question: {question_text}")
        
        for attempt in range(MAX_RETRIES):
            try:
                # Use the new philosophical debate generation method
                debate_data = self.api.generate_philosophical_debate(question_text)
                if debate_data:
                    # Add metadata
                    result = {
                        **debate_data,
                        'seed_question': question_data,
                        'category': question_data.get('category', '哲学'),
                        'difficulty': question_data.get('difficulty', '中等'),
                        'timestamp': time.strftime("%Y-%m-%d %H:%M:%S")
                    }
                    self.processed_questions.add(question_text)
                    return result
                else:
                    logger.warning(f"Attempt {attempt + 1} failed to generate debate for question")
            except Exception as e:
                logger.error(f"Error expanding question (attempt {attempt + 1}): {e}")
                
            if attempt < MAX_RETRIES - 1:
                wait_time = (2 ** attempt) + random.uniform(0, 1)  # Add jitter
                logger.info(f"Waiting {wait_time:.1f} seconds before retry...")
                time.sleep(wait_time)
        
        logger.error(f"Failed to expand question after {MAX_RETRIES} attempts: {question_text}")
        return None
    
    def process_batch(self, questions: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """Process a batch of questions and return the expanded data."""
        expanded_data = []
        for question in tqdm(questions, desc="Processing questions"):
            result = self.expand_question(question)
            if result:
                expanded_data.append(result)
                
                # Save after each question to ensure progress isn't lost
                current_data = self.existing_data + expanded_data
                self.save_expanded_data(current_data)
                
                # Add a delay between API calls to avoid rate limiting
                if len(expanded_data) < len(questions):  # Don't wait after the last one
                    wait_time = DELAY_BETWEEN_REQUESTS + random.uniform(0, 1)  # Add some jitter
                    time.sleep(wait_time)
        
        return expanded_data
    
    def run(self) -> None:
        """Run the dataset expansion process."""
        logger.info("Starting philosophical debate dataset expansion")
        start_time = time.time()
        
        # Load existing data to avoid reprocessing
        self.load_existing_expanded_data()
        
        # Load seed questions
        seed_questions = self.load_seed_questions()
        if not seed_questions:
            logger.error("No seed questions found or failed to load")
            return
            
        logger.info(f"Loaded {len(seed_questions)} seed questions")
        
        # Filter out already processed questions
        new_questions = [
            q for q in seed_questions 
            if q.get('question') not in self.processed_questions
        ]
        
        if not new_questions:
            logger.info("No new questions to process")
            return
            
        logger.info(f"Found {len(new_questions)} new questions to process")
        
        # Process in batches
        total_batches = (len(new_questions) + BATCH_SIZE - 1) // BATCH_SIZE
        for batch_num, i in enumerate(range(0, len(new_questions), BATCH_SIZE), 1):
            batch = new_questions[i:i + BATCH_SIZE]
            logger.info(f"Processing batch {batch_num}/{total_batches} ({len(batch)} questions)")
            
            expanded_batch = self.process_batch(batch)
            if expanded_batch:
                self.existing_data.extend(expanded_batch)
                logger.info(f"Completed batch {batch_num}/{total_batches}, "
                           f"processed: {len(expanded_batch)} questions, "
                           f"total expanded: {len(self.existing_data)}")
            
            # Add a longer delay between batches if not the last batch
            if i + BATCH_SIZE < len(new_questions):
                wait_time = DELAY_BETWEEN_REQUESTS * 3
                logger.info(f"Batch completed. Waiting {wait_time:.1f} seconds before next batch...")
                time.sleep(wait_time)
        
        # Final save
        if self.existing_data:
            self.save_expanded_data(self.existing_data)
        
        elapsed = time.time() - start_time
        logger.info(f"Dataset expansion completed in {elapsed/60:.1f} minutes. "
                   f"Processed {len(new_questions)} questions, "
                   f"total expanded questions: {len(self.existing_data)}")


def main():
    """Main function to run the dataset expansion."""
    try:
        expander = DatasetExpander()
        expander.run()
    except KeyboardInterrupt:
        logger.info("Process interrupted by user")
    except Exception as e:
        logger.exception("An unexpected error occurred")
        raise
    finally:
        # Ensure all logs are flushed
        for handler in logging.root.handlers:
            handler.flush()


if __name__ == "__main__":
    main()
