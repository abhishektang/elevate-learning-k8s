from django.contrib.auth.models import User
from django.db import models
from django.utils import timezone

class UserDetail(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)  # Link to Django's built-in User model
    firstname = models.CharField(max_length=100)
    surname = models.CharField(max_length=100)
    mobile_no = models.CharField(max_length=15, blank=True, null=True)
    role = models.CharField(max_length=100)
    email = models.EmailField(max_length = 254)
    is_archived = models.BooleanField(default=False)

    def __str__(self):
        return f"Details for {self.user.username}"

class Course(models.Model):
    CATEGORY_CHOICES = [
        ('programming', 'Programming'),
        ('design', 'Design'),
        ('business', 'Business'),
        ('science', 'Science'),
        ('others', 'Others'),
    ]
    
    course_id = models.AutoField(primary_key=True)
    title = models.CharField(max_length=200)
    description = models.TextField()  # For storing paragraphs of text
    creator = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='created_courses',
        limit_choices_to={'userdetail__role': 'educator'}  # Ensures only users with educator role can be creators
    )
    learners = models.ManyToManyField(
        User,
        related_name='enrolled_courses',
        blank=True,
        limit_choices_to={'userdetail__role': 'learner'}  # Ensures only users with learner role can enroll
    )
    category = models.CharField(
        max_length=20,
        choices=CATEGORY_CHOICES,
        default='programming'
    )
    created_date = models.DateTimeField(default=timezone.now)
    modified_date = models.DateTimeField(auto_now=True)
    is_archived = models.BooleanField(default=False)

    def __str__(self):
        return f"{self.title} (Course ID: {self.course_id})"

class QRcode(models.Model):
    qrcode_id = models.AutoField(primary_key=True)
    course = models.OneToOneField(
        Course,
        on_delete=models.CASCADE,
        related_name='qrcode'
    )
    qrcode_url = models.URLField(max_length=500)
    created_at = models.DateTimeField(default=timezone.now)
    modified_at = models.DateTimeField(auto_now=True)
    is_archived = models.BooleanField(default=False)

    def __str__(self):
        return f"QR Code for {self.course.title} (ID: {self.qrcode_id})"

    class Meta:
        verbose_name = "QR Code"
        verbose_name_plural = "QR Codes"

class CoursePage(models.Model):
    coursepage_id = models.AutoField(primary_key=True)
    course = models.ForeignKey(
        Course,
        on_delete=models.CASCADE,
        related_name='pages'
    )
    page_title = models.CharField(max_length=200)
    page_description = models.TextField()  # For storing multiple paragraphs
    is_completed = models.BooleanField(default=False)
    page_no = models.PositiveIntegerField()  # To maintain page order
    created_at = models.DateTimeField(default=timezone.now)
    modified_at = models.DateTimeField(auto_now=True)
    is_archived = models.BooleanField(default=False)

    def __str__(self):
        return f"{self.page_title} (Course: {self.course.title}, Page: {self.page_no})"

    class Meta:
        ordering = ['page_no']  # Ensures pages are ordered by page number
        unique_together = ('course', 'page_no')  # Ensures page numbers are unique per course

    def save(self, *args, **kwargs):
        # Auto-increment page_no if not provided
        if not self.page_no:
            last_page = CoursePage.objects.filter(course=self.course).order_by('-page_no').first()
            self.page_no = last_page.page_no + 1 if last_page else 1
        super().save(*args, **kwargs)

class CourseProgress(models.Model):
    learner = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='course_progress',
        limit_choices_to={'userdetail__role': 'learner'}
    )
    course = models.ForeignKey(
        Course,
        on_delete=models.CASCADE,
        related_name='progress_records'
    )
    current_page = models.ForeignKey(
        CoursePage,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='active_progress'
    )
    completed_pages = models.ManyToManyField(
        CoursePage,
        related_name='completed_by',
        blank=True
    )
    started_at = models.DateTimeField(default=timezone.now)
    completed_at = models.DateTimeField(null=True, blank=True)
    last_updated = models.DateTimeField(auto_now=True)
    is_archived = models.BooleanField(default=False)

    class Meta:
        unique_together = ('learner', 'course')  # One progress record per learner per course
        verbose_name_plural = 'Course Progress Records'

    def __str__(self):
        return f"{self.learner.username}'s progress in {self.course.title}"

    @property
    def is_completed(self):
        """Check if the course is fully completed"""
        total_pages = self.course.pages.count()
        return total_pages > 0 and self.completed_pages.count() == total_pages

    @property
    def progress_percentage(self):
        """Calculate progress as a float between 0 and 1"""
        total_pages = self.course.pages.count()
        if total_pages == 0:
            return 0.0
        return float(self.completed_pages.count()) / float(total_pages)

    def get_progress_display(self):
        """Return progress as percentage string"""
        return f"{self.progress_percentage:.0%}"

    def update_progress(self, page, is_completed=True):
        """Update progress when a page is completed"""
        if is_completed:
            self.completed_pages.add(page)
        else:
            self.completed_pages.remove(page)
        
        self.current_page = self.get_next_incomplete_page()
        if self.is_completed:
            self.completed_at = timezone.now()
        self.save()

    def get_next_incomplete_page(self):
        """Get the next page that hasn't been completed"""
        completed_ids = self.completed_pages.values_list('coursepage_id', flat=True)
        return self.course.pages.exclude(coursepage_id__in=completed_ids).order_by('page_no').first()
    
class CourseInteraction(models.Model):
    course_page = models.ForeignKey(
        CoursePage, 
        on_delete=models.CASCADE,
        related_name='interactions'
    )
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='course_interactions'
    )
    liked = models.BooleanField(default=False)
    shared = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    is_archived = models.BooleanField(default=False)

    class Meta:
        unique_together = ('course_page', 'user')

class CourseComment(models.Model):
    course_page = models.ForeignKey(
        CoursePage,
        on_delete=models.CASCADE,
        related_name='comments'
    )
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='course_comments'
    )
    text = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    is_archived = models.BooleanField(default=False)

    class Meta:
        ordering = ['-created_at']




# Create your models here.
