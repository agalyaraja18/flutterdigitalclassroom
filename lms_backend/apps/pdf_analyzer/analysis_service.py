"""
Service for PDF Analysis module - handles AI interactions using Google Gemini API
"""
import os
import uuid
import json
import re
from datetime import timedelta
from django.conf import settings
from django.utils import timezone
try:
    import google.generativeai as genai
except ImportError:
    genai = None

try:
    from PyPDF2 import PdfReader
except ImportError:
    PdfReader = None


class PDFAnalysisService:
    """Service to handle PDF analysis using Google Gemini API"""
    
    def __init__(self):
        """Initialize Gemini client with API key from environment"""
        api_key = os.getenv('AI_API_KEY') or getattr(settings, 'AI_API_KEY', None)
        if not api_key or genai is None:
            raise ValueError("AI_API_KEY environment variable not set or google-generativeai library not installed")
        
        try:
            genai.configure(api_key=api_key)
            # Using gemini-2.5-flash as default (stable and widely available)
            model_name = getattr(settings, 'PDF_ANALYSIS_MODEL', 'gemini-2.5-flash')
            self.model = genai.GenerativeModel(model_name)
            self.model_name = model_name
        except Exception as e:
            raise ValueError(f"Failed to initialize Gemini API: {str(e)}")
        
        self.max_tokens = 2400
        self.temperature = 0.2
    
    def extract_text_from_pdf(self, pdf_file):
        """Extract text content from PDF file with page information"""
        try:
            pdf_file.seek(0)
        except Exception:
            pass
        
        if PdfReader is None:
            # Fallback: try to decode raw bytes
            try:
                raw = pdf_file.read()
                if not raw:
                    return [], 0
                try:
                    text = raw.decode('utf-8', errors='ignore')
                    text = text.replace('\x00', ' ').strip()
                    return [{'page': 1, 'text': text}], 1
                except Exception:
                    return [], 0
            except Exception:
                return [], 0
        
        try:
            pdf_reader = PdfReader(pdf_file)
            pages = []
            
            for page_num, page in enumerate(pdf_reader.pages, start=1):
                try:
                    page_text = page.extract_text() or ''
                    if page_text.strip():
                        pages.append({
                            'page': page_num,
                            'text': page_text
                        })
                except Exception:
                    continue
            
            return pages, len(pdf_reader.pages)
        except Exception as e:
            print(f"Error extracting text from PDF: {e}")
            return [], 0
    
    def split_into_chunks(self, pages, max_chunk_size=3000):
        """Split pages into chunks for processing"""
        chunks = []
        current_chunk = []
        current_size = 0
        
        for page_data in pages:
            page_text = page_data['text']
            page_num = page_data['page']
            
            if current_size + len(page_text) > max_chunk_size and current_chunk:
                chunks.append({
                    'pages': [p['page'] for p in current_chunk],
                    'text': '\n\n'.join([p['text'] for p in current_chunk])
                })
                current_chunk = [page_data]
                current_size = len(page_text)
            else:
                current_chunk.append(page_data)
                current_size += len(page_text)
        
        if current_chunk:
            chunks.append({
                'pages': [p['page'] for p in current_chunk],
                'text': '\n\n'.join([p['text'] for p in current_chunk])
            })
        
        return chunks
    
    def generate_prompt(self, task, task_options, pdf_content):
        """Generate prompt based on task type"""
        if task == 'summarize':
            length = task_options.get('summarize_length', 'medium')
            length_map = {
                'short': 'brief',
                'medium': 'moderate',
                'long': 'comprehensive'
            }
            length_desc = length_map.get(length, 'moderate')
            
            prompt = f"""Generate a {length_desc} summary of the provided PDF content. 
Keep references to page numbers for statements where possible.

PDF Content:
{pdf_content}

Provide a {length_desc} summary with page references."""
        
        elif task == 'explain':
            topic = task_options.get('explain_topic', '')
            if not topic:
                raise ValueError("explain_topic is required for 'explain' task")
            
            prompt = f"""Explain the following topic in the uploaded document: "{topic}"

Provide examples and point to page numbers where the topic appears.

PDF Content:
{pdf_content}

Explain the topic "{topic}" with examples and page references."""
        
        elif task == 'answer':
            question = task_options.get('question', '')
            if not question:
                raise ValueError("question is required for 'answer' task")
            
            prompt = f"""Answer the user's question using only information from the supplied PDF content. 
If the answer is not present, say 'I could not find that in the document.'

Question: {question}

PDF Content:
{pdf_content}

Answer the question using only the provided content."""
        
        else:
            raise ValueError(f"Unknown task type: {task}")
        
        return prompt
    
    def analyze_content(self, task, task_options, pdf_content, response_format='text'):
        """Analyze PDF content using Google Gemini API"""
        try:
            prompt = self.generate_prompt(task, task_options, pdf_content)
            
            # Add system instruction to the prompt for Gemini
            full_prompt = f"""You are a helpful assistant that analyzes PDF documents and provides accurate, well-referenced answers.

{prompt}"""
            
            # Configure generation config using genai.types.GenerationConfig
            generation_config = genai.types.GenerationConfig(
                temperature=self.temperature,
                max_output_tokens=self.max_tokens,
            )
            
            response = self.model.generate_content(
                full_prompt,
                generation_config=generation_config
            )
            
            content = response.text
            
            # Extract page references from content (simple heuristic)
            references = self._extract_page_references(content, pdf_content)
            
            result = {
                'type': task,
                'content': content,
                'references': references
            }
            
            # Format response based on response_format
            if response_format == 'json':
                return result
            elif response_format == 'bulleted':
                # Convert to bulleted format
                lines = content.split('\n')
                bulleted = '\n'.join([f"• {line.strip()}" if line.strip() and not line.strip().startswith('•') else line for line in lines])
                result['content'] = bulleted
                return result
            else:  # text
                return result
        
        except Exception as e:
            raise Exception(f"Error analyzing content: {str(e)}")
    
    def _extract_page_references(self, content, pdf_content):
        """Extract page references from content (simple heuristic)"""
        references = []
        # Look for patterns like "page 1", "p. 2", etc.
        page_patterns = [
            r'page\s+(\d+)',
            r'p\.\s*(\d+)',
            r'pages?\s+(\d+)',
        ]
        
        found_pages = set()
        for pattern in page_patterns:
            matches = re.finditer(pattern, content, re.IGNORECASE)
            for match in matches:
                page_num = int(match.group(1))
                found_pages.add(page_num)
        
        # Create references with text snippets
        for page_num in sorted(found_pages):
            # Try to find text snippet from that page
            snippet = self._get_page_snippet(pdf_content, page_num)
            references.append({
                'page': page_num,
                'text_snippet': snippet[:200] if snippet else ''
            })
        
        return references
    
    def _get_page_snippet(self, pdf_content, page_num):
        """Get a text snippet from a specific page"""
        # This is a simplified version - in production, you'd want to store page-level text
        if isinstance(pdf_content, str):
            # If pdf_content is a string, try to find page markers
            lines = pdf_content.split('\n')
            # Return first few lines as snippet
            return '\n'.join(lines[:3]) if lines else ''
        return ''
    
    def estimate_cost(self, input_tokens, output_tokens):
        """Estimate cost based on token usage (approximate)"""
        # Gemini 2.5 Flash pricing (as of 2024): Free tier available, paid tier is very low cost
        # For estimation purposes, using approximate values
        # Note: Gemini has generous free tier, so cost is often $0
        input_cost_per_1k = 0.0  # Free tier
        output_cost_per_1k = 0.0  # Free tier
        
        cost = (input_tokens / 1000 * input_cost_per_1k) + (output_tokens / 1000 * output_cost_per_1k)
        return round(cost, 6)


# Singleton instance
_analysis_service = None

def get_analysis_service():
    """Get or create the analysis service instance"""
    global _analysis_service
    if _analysis_service is None:
        try:
            _analysis_service = PDFAnalysisService()
        except ValueError as e:
            print(f"Warning: {e}")
            return None
    return _analysis_service

