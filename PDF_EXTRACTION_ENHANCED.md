# PDF Text Extraction - Enhanced with Multiple Strategies

## What Was Done

Enhanced the PDF text extraction with multiple fallback strategies to handle different types of PDFs.

## Changes Made

### Enhanced `extract_text_from_pdf()` Function

Added 3 extraction strategies that are tried in sequence:

1. **Strategy 1**: Standard `extract_text()` method
2. **Strategy 2**: Layout mode extraction with custom parameters
3. **Strategy 3**: Direct content stream extraction

Also added:
- Better text cleaning (removes excessive whitespace)
- More detailed logging for debugging
- Tries all strategies before giving up

## How to Test

### Method 1: Upload a New PDF

1. **Restart Django server**:
   ```bash
   cd lms_backend
   python manage.py runserver
   ```

2. **Upload a PDF** through the app

3. **Watch the Django console** for detailed logs:
   ```
   Starting PDF processing for: [Your PDF]
   Extracting text from PDF...
   File pointer reset to beginning. File size: [size]
   Creating PDF reader...
   PDF has [N] pages
   Page 1: Extracted [N] characters
   Page 2: Extracted [N] characters
   ...
   Total pages with text: [N]/[N]
   Total text length: [N] characters
   ```

### Method 2: Test Existing PDF

Run the test script to check your most recent upload:

```bash
python test_pdf_extraction.py
```

This will show you:
- Which PDF is being tested
- Detailed extraction logs
- First 500 characters of extracted text
- Whether extraction succeeded or failed

## Debugging Steps

### If Still Getting "No text can be extracted"

1. **Check the console output** when uploading - look for:
   ```
   Page 1: No text found after all strategies
   Total pages with text: 0/[N]
   ERROR: No text could be extracted from any page!
   ```

2. **Run the test script** to see detailed extraction attempt

3. **Check if your PDF is**:
   - A scanned image (needs OCR - not supported yet)
   - Password protected
   - Using special fonts or encoding

### If You See Text in Console But Audio Says "No text"

This means the extraction is working but something else is wrong. Check:
1. Is the text being saved to `pdf_document.text_content`?
2. Is the audio conversion using the right text?

## Common PDF Issues

### Scanned PDFs (Images)
- **Problem**: PDF contains images of text, not actual text
- **Solution**: Needs OCR (Optical Character Recognition)
- **Workaround**: Use a tool to OCR the PDF first, or add OCR library

### Protected PDFs
- **Problem**: PDF has restrictions on text extraction
- **Solution**: Remove protection or use password

### Special Encoding
- **Problem**: PDF uses fonts/encoding PyPDF2 can't handle
- **Solution**: Try converting PDF to a standard format first

## Next Steps if Still Not Working

### Option 1: Add OCR Support

Install Tesseract OCR:
```bash
pip install pytesseract pdf2image
```

Then add OCR fallback to extraction function.

### Option 2: Try Different PDF Library

Install pdfplumber (better for some PDFs):
```bash
pip install pdfplumber
```

### Option 3: Check Specific PDF

Send me the console output from:
```bash
python test_pdf_extraction.py
```

This will help identify the specific issue with your PDF.

## Files Changed

- `lms_backend/apps/pdf_converter/utils.py` - Enhanced extraction with 3 strategies
- `test_pdf_extraction.py` - New test script for debugging

## What to Look For

When you upload a PDF and check the Django console, you should see:

**✓ Success:**
```
Page 1: Extracted 1234 characters
Page 2: Extracted 567 characters
Total pages with text: 2/2
Total text length: 1801 characters
Text extracted successfully. Length: 1801 characters
```

**✗ Failure:**
```
Page 1: Standard extraction failed: [error]
Page 1: Layout extraction failed: [error]
Page 1: No text found after all strategies
Total pages with text: 0/1
ERROR: No text could be extracted from any page!
```

If you see the failure pattern, your PDF likely needs OCR or is in an unsupported format.
