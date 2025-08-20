import json
import os
from pathlib import Path
from typing import Dict, List, Any
import random
from loguru import logger
from tqdm import tqdm

# Configure logging
logger.add("logs/prepare_training_data.log", rotation="10 MB")

class TrainingDataPreparer:
    def __init__(self, input_path: str, output_dir: str):
        """
        Initialize the training data preparer.
        
        Args:
            input_path: Path to the input JSON file containing philosophical debates
            output_dir: Directory to save the prepared training data
        """
        self.input_path = input_path
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)
        
        # Training data splits
        self.train_data = []
        self.val_data = []
        self.test_data = []
        
        # Split ratios
        self.train_ratio = 0.8
        self.val_ratio = 0.1
        self.test_ratio = 0.1
    
    def load_data(self) -> List[Dict[str, Any]]:
        """Load the philosophical debates data."""
        logger.info(f"Loading data from {self.input_path}")
        with open(self.input_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        logger.info(f"Loaded {len(data)} philosophical debates")
        return data
    
    def convert_to_training_format(self, debate: Dict[str, Any]) -> List[Dict[str, str]]:
        """Convert a single debate into training examples."""
        examples = []
        
        # Create examples for each standpoint
        for standpoint in debate.get('standpoints', []):
            # Create instruction
            instruction = f"请基于以下哲学问题，提出一个明确的立场并给出支持论据：\n\n问题：{debate['question']}\n\n立场：{standpoint['text']}"
            
            # Create response with arguments
            arguments = "\n".join([f"- {arg['text']}" for arg in standpoint.get('arguments', [])])
            response = f"论据：\n{arguments}"
            
            examples.append({
                "instruction": instruction,
                "input": "",
                "output": response,
                "category": debate.get('category', '哲学')
            })
            
            # Create examples for counter-questions
            for cq in debate.get('counter_questions', []):
                cq_instruction = f"请针对以下哲学立场，提出一个具有挑战性的反问：\n\n问题：{debate['question']}\n立场：{standpoint['text']}\n"
                cq_response = f"反问：{cq['text']}"
                
                examples.append({
                    "instruction": cq_instruction,
                    "input": "",
                    "output": cq_response,
                    "category": debate.get('category', '哲学') + "-反问"
                })
        
        return examples
    
    def split_data(self, data: List[Dict[str, str]]) -> None:
        """Split data into train, validation, and test sets."""
        # Shuffle the data
        random.shuffle(data)
        
        # Calculate split indices
        n = len(data)
        train_end = int(n * self.train_ratio)
        val_end = train_end + int(n * self.val_ratio)
        
        # Split the data
        self.train_data = data[:train_end]
        self.val_data = data[train_end:val_end]
        self.test_data = data[val_end:]
        
        logger.info(f"Split data into: {len(self.train_data)} train, "
                   f"{len(self.val_data)} validation, {len(self.test_data)} test examples")
    
    def save_data(self) -> None:
        """Save the prepared data to files."""
        # Save training data
        train_path = self.output_dir / "train.jsonl"
        with open(train_path, 'w', encoding='utf-8') as f:
            for example in self.train_data:
                f.write(json.dumps(example, ensure_ascii=False) + '\n')
        
        # Save validation data
        val_path = self.output_dir / "val.jsonl"
        with open(val_path, 'w', encoding='utf-8') as f:
            for example in self.val_data:
                f.write(json.dumps(example, ensure_ascii=False) + '\n')
        
        # Save test data
        test_path = self.output_dir / "test.jsonl"
        with open(test_path, 'w', encoding='utf-8') as f:
            for example in self.test_data:
                f.write(json.dumps(example, ensure_ascii=False) + '\n')
        
        logger.info(f"Saved training data to {train_path}")
        logger.info(f"Saved validation data to {val_path}")
        logger.info(f"Saved test data to {test_path}")
    
    def prepare_data(self) -> None:
        """Prepare the training data."""
        # Load the data
        debates = self.load_data()
        
        # Convert to training format
        all_examples = []
        for debate in tqdm(debates, desc="Processing debates"):
            try:
                examples = self.convert_to_training_format(debate)
                all_examples.extend(examples)
            except Exception as e:
                logger.error(f"Error processing debate {debate.get('question', 'unknown')}: {str(e)}")
        
        logger.info(f"Generated {len(all_examples)} training examples from {len(debates)} debates")
        
        # Split the data
        self.split_data(all_examples)
        
        # Save the data
        self.save_data()


if __name__ == "__main__":
    # Configuration
    INPUT_PATH = "data/philosophical_debates.json"
    OUTPUT_DIR = "data/processed"
    
    # Prepare the data
    preparer = TrainingDataPreparer(INPUT_PATH, OUTPUT_DIR)
    preparer.prepare_data()
    
    logger.info("Data preparation completed successfully!")
