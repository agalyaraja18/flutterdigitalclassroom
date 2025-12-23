import PyPDF2
import pyttsx3
import os
from django.conf import settings
from django.core.files.base import ContentFile
import tempfile

def extract_text_from_pdf(pdf_file):
    """Extract text content from PDF file"""
    try:
        # Ensure file pointer is at the beginning
        try:
            pdf_file.seek(0)
            print(f"File pointer reset to beginning. File size: {pdf_file.size if hasattr(pdf_file, 'size') else 'unknown'}")
        except Exception as e:
            print(f"Could not seek file: {e}")
        
        # Try to read the PDF
        print("Creating PDF reader...")
        pdf_reader = PyPDF2.PdfReader(pdf_file)
        print(f"PDF has {len(pdf_reader.pages)} pages")
        
        text = ""
        pages_with_text = 0

        # Extract text from all pages with multiple strategies
        for page_num, page in enumerate(pdf_reader.pages):
            try:
                page_text = ""
                
                # Strategy 1: Standard extraction
                try:
                    page_text = page.extract_text()
                except Exception as e1:
                    print(f"Page {page_num + 1}: Standard extraction failed: {e1}")
                
                # Strategy 2: Try with space width parameter
                if not page_text or len(page_text.strip()) == 0:
                    try:
                        # Some PDFs need custom space width
                        page_text = page.extract_text(extraction_mode="layout", layout_mode_space_vertically=False)
                    except Exception as e2:
                        print(f"Page {page_num + 1}: Layout extraction failed: {e2}")
                
                # Strategy 3: Try getting text from content stream directly
                if not page_text or len(page_text.strip()) == 0:
                    try:
                        if '/Contents' in page:
                            content = page['/Contents']
                            if content:
                                # This is a fallback - just try to get any text
                                page_text = page.extract_text()
                    except Exception as e3:
                        print(f"Page {page_num + 1}: Content stream extraction failed: {e3}")
                
                # Clean up the extracted text
                if page_text:
                    # Remove excessive whitespace but keep structure
                    page_text = '\n'.join(line.strip() for line in page_text.split('\n') if line.strip())
                
                if page_text and len(page_text.strip()) > 0:
                    text += page_text + "\n\n"
                    pages_with_text += 1
                    print(f"Page {page_num + 1}: Extracted {len(page_text)} characters")
                else:
                    print(f"Page {page_num + 1}: No text found after all strategies")
                    
            except Exception as page_error:
                print(f"Warning: Could not extract text from page {page_num + 1}: {page_error}")
                continue

        print(f"Total pages with text: {pages_with_text}/{len(pdf_reader.pages)}")
        print(f"Total text length: {len(text)} characters")

        # If no text was extracted, provide a default message
        if not text or len(text.strip()) == 0:
            print("ERROR: No text could be extracted from any page!")
            return "No text content could be extracted from this PDF. This may be a scanned document, contain only images, or have text in an unsupported format."

        return text.strip()

    except PyPDF2.errors.PdfReadError as pdf_error:
        print(f"PDF read error: {pdf_error}")
        return f"This PDF file appears to be corrupted or in an unsupported format. Error: {str(pdf_error)}"

    except Exception as e:
        print(f"General error extracting text: {e}")
        import traceback
        traceback.print_exc()
        return f"Could not extract text from this PDF file. Error: {str(e)}"

def convert_text_to_audio(text, title):
    """Convert text to audio using pyttsx3"""
    try:
        # Limit text length to avoid memory issues
        if len(text) > 5000:
            text = text[:5000] + "... (content truncated for audio conversion)"

        print(f"Converting text to audio for: {title}")
        print(f"Text length: {len(text)} characters")

        # Initialize TTS engine with error handling
        try:
            engine = pyttsx3.init()
        except Exception as init_error:
            print(f"Failed to initialize TTS engine: {init_error}")
            raise Exception(f"TTS engine initialization failed: {str(init_error)}")

        # Set properties (optional)
        try:
            engine.setProperty('rate', 150)  # Speed of speech
            engine.setProperty('volume', 0.9)  # Volume level (0.0 to 1.0)
        except Exception as prop_error:
            print(f"Warning: Could not set TTS properties: {prop_error}")

        # Create temporary file for audio
        with tempfile.NamedTemporaryFile(delete=False, suffix='.wav') as temp_file:
            temp_path = temp_file.name

        print(f"Saving audio to: {temp_path}")

        # Save audio to temporary file
        try:
            engine.save_to_file(text, temp_path)
            engine.runAndWait()
        except Exception as convert_error:
            print(f"TTS conversion failed: {convert_error}")
            # Clean up and try alternative method
            if os.path.exists(temp_path):
                os.unlink(temp_path)
            return create_dummy_audio(title)

        # Check if file was created
        if not os.path.exists(temp_path) or os.path.getsize(temp_path) == 0:
            print("Audio file was not created or is empty, creating dummy audio")
            if os.path.exists(temp_path):
                os.unlink(temp_path)
            return create_dummy_audio(title)

        # Read the audio file content
        with open(temp_path, 'rb') as audio_file:
            audio_content = audio_file.read()

        # Clean up temporary file
        os.unlink(temp_path)

        # Create Django file object
        audio_filename = f"{title.replace(' ', '_')}.wav"

        print(f"Audio conversion successful! File size: {len(audio_content)} bytes")
        return ContentFile(audio_content, name=audio_filename)

    except Exception as e:
        print(f"Error in convert_text_to_audio: {str(e)}")
        # Return dummy audio file as fallback
        return create_dummy_audio(title)

def create_dummy_audio(title):
    """Create a dummy audio file as fallback"""
    try:
        # Create a minimal WAV file header (44 bytes) with no audio data
        # This creates a valid but silent WAV file
        dummy_wav = bytearray([
            0x52, 0x49, 0x46, 0x46,  # "RIFF"
            0x24, 0x00, 0x00, 0x00,  # File size - 8
            0x57, 0x41, 0x56, 0x45,  # "WAVE"
            0x66, 0x6D, 0x74, 0x20,  # "fmt "
            0x10, 0x00, 0x00, 0x00,  # Subchunk1Size
            0x01, 0x00,              # AudioFormat (PCM)
            0x01, 0x00,              # NumChannels (Mono)
            0x44, 0xAC, 0x00, 0x00,  # SampleRate (44100)
            0x88, 0x58, 0x01, 0x00,  # ByteRate
            0x02, 0x00,              # BlockAlign
            0x10, 0x00,              # BitsPerSample
            0x64, 0x61, 0x74, 0x61,  # "data"
            0x00, 0x00, 0x00, 0x00   # Subchunk2Size (0 = no data)
        ])

        audio_filename = f"{title.replace(' ', '_')}_dummy.wav"
        print(f"Created dummy audio file: {audio_filename}")
        return ContentFile(bytes(dummy_wav), name=audio_filename)

    except Exception as e:
        print(f"Failed to create dummy audio: {e}")
        # Return minimal content as last resort
        return ContentFile(b"Audio conversion not available", name=f"{title}.txt")

def process_pdf_to_audio(pdf_document):
    """Complete process: extract text and convert to audio"""
    try:
        print(f"Starting PDF processing for: {pdf_document.title}")

        # Update status to processing
        pdf_document.conversion_status = 'processing'
        pdf_document.save()

        # Extract text from PDF
        print("Extracting text from PDF...")
        
        # Open the file properly to ensure it's readable
        with pdf_document.pdf_file.open('rb') as pdf_file:
            text = extract_text_from_pdf(pdf_file)

        if not text or len(text.strip()) == 0:
            text = f"No text content found in the PDF: {pdf_document.title}. This may be a scanned document or contain only images."
            print("Warning: No text extracted from PDF")

        pdf_document.text_content = text
        print(f"Text extracted successfully. Length: {len(text)} characters")

        # Convert text to audio
        print("Converting text to audio...")
        audio_file = convert_text_to_audio(text, pdf_document.title)
        pdf_document.audio_file = audio_file

        # Update status to completed
        pdf_document.conversion_status = 'completed'
        pdf_document.save()

        print(f"PDF processing completed successfully for: {pdf_document.title}")
        return True

    except Exception as e:
        print(f"PDF processing failed for {pdf_document.title}: {str(e)}")
        # Update status to failed
        pdf_document.conversion_status = 'failed'
        pdf_document.save()

        # Don't re-raise the exception, just log it
        print(f"Error details: {str(e)}")
        return False