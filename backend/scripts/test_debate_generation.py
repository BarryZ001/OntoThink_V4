#!/usr/bin/env python3
"""
Test script for generating philosophical debate data.
"""
import json
import sys
from pathlib import Path

# Add the project root to the Python path
sys.path.append(str(Path(__file__).parent.parent))

from app.data_processing.deepseek_api import DeepSeekAPI

def test_single_question():
    """Test generating debate data for a single question."""
    api = DeepSeekAPI()
    
    test_question = {
        "id": 999,
        "question": "自由意志是否真实存在？",
        "category": "形而上学",
        "difficulty": "高",
        "tags": ["自由意志", "决定论", "形而上学"]
    }
    
    print(f"Testing debate generation for question: {test_question['question']}")
    print("-" * 80)
    
    debate_data = api.generate_philosophical_debate(test_question['question'])
    
    if debate_data:
        print("\nSuccessfully generated debate data:")
        print(json.dumps(debate_data, ensure_ascii=False, indent=2))
        
        # Validate the structure
        required_fields = ['question', 'standpoints', 'counter_questions']
        valid = all(field in debate_data for field in required_fields)
        
        if valid:
            print("\n✅ Data structure is valid!")
            print(f"- Found {len(debate_data['standpoints'])} standpoints")
            for i, standpoint in enumerate(debate_data['standpoints'], 1):
                print(f"  - Standpoint {i}: {len(standpoint.get('arguments', []))} arguments")
            print(f"- Found {len(debate_data['counter_questions'])} counter questions")
        else:
            print("\n❌ Invalid data structure. Missing required fields.")
            missing = [f for f in required_fields if f not in debate_data]
            print(f"Missing fields: {', '.join(missing)}")
    else:
        print("\n❌ Failed to generate debate data")

if __name__ == "__main__":
    test_single_question()
