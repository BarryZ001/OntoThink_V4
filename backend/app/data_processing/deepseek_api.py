import json
import time
import logging
from typing import Dict, List, Optional, Any
import requests
from .config import (
    DEEPSEEK_API_KEY, DEEPSEEK_API_BASE, MODEL_NAME,
    MAX_TOKENS, TEMPERATURE, TIMEOUT, MAX_RETRIES
)
from .philosophy_prompt import PHILOSOPHY_PROMPT

# Set up logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class DeepSeekAPI:
    """A class to handle interactions with the DeepSeek API for philosophical debate data generation."""
    
    def __init__(self, api_key: str = DEEPSEEK_API_KEY):
        """Initialize the DeepSeek API client."""
        self.api_key = api_key
        self.base_url = f"{DEEPSEEK_API_BASE}/chat/completions"
        self.headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json"
        }
    
    def _make_api_call(self, messages: List[Dict[str, str]]) -> Optional[Dict[str, Any]]:
        """Make a single API call to the DeepSeek API."""
        payload = {
            "model": MODEL_NAME,
            "messages": messages,
            "temperature": TEMPERATURE,
            "max_tokens": MAX_TOKENS,
            "response_format": { "type": "json_object" }
        }
        
        for attempt in range(MAX_RETRIES):
            try:
                response = requests.post(
                    self.base_url,
                    headers=self.headers,
                    json=payload,
                    timeout=TIMEOUT
                )
                response.raise_for_status()
                return response.json()
            except requests.exceptions.RequestException as e:
                logger.warning(f"Attempt {attempt + 1} failed: {str(e)}")
                if attempt < MAX_RETRIES - 1:
                    time.sleep(2 ** attempt)  # Exponential backoff
                else:
                    logger.error(f"All {MAX_RETRIES} attempts failed")
                    return None
    
    def generate_philosophical_debate(self, question: str) -> Optional[Dict[str, Any]]:
        """Generate a philosophical debate structure for the given question.
        
        Args:
            question: The philosophical question to generate debate for
            
        Returns:
            Dict containing the debate structure or None if generation fails
        """
        system_prompt = """你是一个专业的哲学思辨图谱数据生成助手。你的任务是根据给定的哲学问题，
        生成包含不同立场、支持论据和反问的思辨图谱数据。请严格遵循指定的JSON格式输出，
        并确保内容的哲学深度和逻辑严谨性。"""
        
        # Create the user prompt with the specific question
        user_prompt = f"{PHILOSOPHY_PROMPT}\n\n{question}"
        
        # Make the API call
        response = self._make_api_call([
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_prompt}
        ])
        
        if not response or 'choices' not in response or not response['choices']:
            logger.error("Failed to get valid response from API")
            return None
        
        # Extract the content from the response
        content = response['choices'][0]['message']['content']
        
        # Clean up the response (handle markdown code blocks if present)
        if '```json' in content:
            content = content.split('```json')[1].split('```')[0].strip()
        elif '```' in content:
            content = content.split('```')[1].strip()
            if content.startswith('json'):
                content = content[4:].strip()
        
        try:
            # Parse the JSON response
            debate_data = json.loads(content)
            
            # Validate the structure
            required_fields = ['question', 'standpoints', 'counter_questions']
            for field in required_fields:
                if field not in debate_data:
                    logger.error(f"Missing required field in response: {field}")
                    return None
            
            # Validate standpoints
            if not isinstance(debate_data['standpoints'], list) or len(debate_data['standpoints']) < 2:
                logger.error("At least two standpoints are required")
                return None
                
            for i, standpoint in enumerate(debate_data['standpoints'], 1):
                if 'id' not in standpoint or standpoint['id'] != f'standpoint_{i}':
                    logger.error(f"Invalid or missing id for standpoint {i}")
                    return None
                if 'arguments' not in standpoint or not isinstance(standpoint['arguments'], list) or len(standpoint['arguments']) < 2:
                    logger.error(f"At least two arguments are required for standpoint {i}")
                    return None
                
                # Validate arguments
                for j, argument in enumerate(standpoint['arguments'], 1):
                    if 'id' not in argument or argument['id'] != f'argument_{i}_{j}':
                        logger.error(f"Invalid or missing id for argument {j} in standpoint {i}")
                        return None
            
            # Validate counter questions
            if not isinstance(debate_data['counter_questions'], list) or len(debate_data['counter_questions']) < 2:
                logger.error("At least two counter questions are required")
                return None
                
            for i, question in enumerate(debate_data['counter_questions'], 1):
                if 'id' not in question or question['id'] != f'counter_question_{i}':
                    logger.error(f"Invalid or missing id for counter question {i}")
                    return None
            
            return debate_data
            
        except json.JSONDecodeError as e:
            logger.error(f"Failed to parse response as JSON: {e}")
            logger.debug(f"Response content: {content}")
            return None
        except Exception as e:
            logger.error(f"Error validating response: {e}")
            return None
