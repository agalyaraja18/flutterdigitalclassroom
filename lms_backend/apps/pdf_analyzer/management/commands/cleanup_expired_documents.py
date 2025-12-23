"""
Management command to clean up expired PDF analysis documents
Run this periodically (e.g., via cron) to remove expired documents
"""
from django.core.management.base import BaseCommand
from django.utils import timezone
from apps.pdf_analyzer.models import AnalysisDocument
import os


class Command(BaseCommand):
    help = 'Clean up expired PDF analysis documents based on retention policy'

    def add_arguments(self, parser):
        parser.add_argument(
            '--dry-run',
            action='store_true',
            help='Show what would be deleted without actually deleting',
        )

    def handle(self, *args, **options):
        dry_run = options['dry_run']
        now = timezone.now()
        
        # Find expired documents
        expired_docs = AnalysisDocument.objects.filter(expires_at__lt=now)
        count = expired_docs.count()
        
        if count == 0:
            self.stdout.write(self.style.SUCCESS('No expired documents found.'))
            return
        
        self.stdout.write(f'Found {count} expired document(s).')
        
        if dry_run:
            self.stdout.write(self.style.WARNING('DRY RUN - No files will be deleted.'))
            for doc in expired_docs:
                self.stdout.write(f'  Would delete: {doc.file_id} (expired at {doc.expires_at})')
        else:
            deleted_count = 0
            for doc in expired_docs:
                try:
                    # Delete the file if it exists
                    if doc.pdf_file and os.path.exists(doc.pdf_file.path):
                        os.remove(doc.pdf_file.path)
                    
                    # Delete the database record
                    doc.delete()
                    deleted_count += 1
                    self.stdout.write(f'Deleted: {doc.file_id}')
                except Exception as e:
                    self.stdout.write(
                        self.style.ERROR(f'Error deleting {doc.file_id}: {str(e)}')
                    )
            
            self.stdout.write(
                self.style.SUCCESS(f'Successfully deleted {deleted_count} document(s).')
            )

