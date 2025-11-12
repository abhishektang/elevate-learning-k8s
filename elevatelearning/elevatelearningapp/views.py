from django.shortcuts import render, redirect, get_object_or_404
from django.views import View
from django.contrib.auth import authenticate, login, logout
from django.db.models import Subquery
from django.contrib.auth.models import User
from django.contrib.auth.decorators import login_required
from django.views.decorators.http import require_POST
from django.http import JsonResponse
from django.contrib import messages
from django.core.exceptions import ValidationError
from django.contrib.auth.hashers import make_password
import uuid
from django.utils import timezone
from .models import UserDetail, Course, CoursePage, CourseProgress, QRcode, CourseInteraction, CourseComment

def index(request):
    return render(request, "home.html")

def dashboard(request):
    return render(request, "dashboard.html")

def logout_view(request):
    logout(request)
    return redirect('index') 

@login_required
def coursecreate(request):
    if request.method == 'POST':
        # Check if the user is an educator
        if not hasattr(request.user, 'userdetail') or request.user.userdetail.role.lower() != 'educator':
            messages.error(request, "Only educators can create courses.")
            return redirect('dashboard')
        
        title = request.POST.get('course-title')
        description = request.POST.get('course-description')
        category = request.POST.get('course-category')
        
        if not all([title, description, category]):
            messages.error(request, "Please fill all required fields.")
            return redirect('coursecreate')
        
        try:
            # Create the course
            course = Course.objects.create(
                title=title,
                description=description,
                category=category,
                creator=request.user
            )
            messages.success(request, f"Course '{title}' created successfully!")
            return redirect('createdcourses')  # Or wherever you want to redirect after creation
        except Exception as e:
            messages.error(request, f"Error creating course: {str(e)}")
            return redirect('coursecreate')
    
    # For GET requests, just render the form
    return render(request, "coursecreate.html")


def coursepage(request, coursepage_id):
    if not hasattr(request.user, 'userdetail') or request.user.userdetail.role.lower() != 'learner':
        messages.error(request, "Only learners can access course pages.")
        return redirect('dashboard')
    
    page = get_object_or_404(CoursePage, coursepage_id=coursepage_id)
    course = page.course

     # Get interactions
    interactions = CourseInteraction.objects.filter(course_page=page)
    likes_count = interactions.filter(liked=True).count()
    shares_count = interactions.filter(shared=True).count()
    user_interaction = None
    
    # Check if user is enrolled in this course
    if not request.user.enrolled_courses.filter(pk=course.course_id).exists():
        messages.error(request, "You need to enroll in this course first.")
        return redirect('mycourse')
    
    # Get or create progress
    progress, created = CourseProgress.objects.get_or_create(
        learner=request.user,
        course=course,
        defaults={'current_page': page}
    )
    
    # Update current page if different
    if progress.current_page != page:
        progress.current_page = page
        progress.save()
    
    # Mark page as completed if not already
    if not progress.completed_pages.filter(pk=page.coursepage_id).exists():
        progress.completed_pages.add(page)
    
    # Get next and previous pages
    all_pages = list(course.pages.order_by('page_no'))
    current_index = all_pages.index(page)
    previous_page = all_pages[current_index - 1] if current_index > 0 else None
    next_page = all_pages[current_index + 1] if current_index < len(all_pages) - 1 else None

    if request.user.is_authenticated:
        user_interaction = CourseInteraction.objects.filter(
            course_page=page,
            user=request.user
        ).first()

     # Get comments
    comments = CourseComment.objects.filter(course_page=page).select_related('user')
    
    context = {
        'page': page,
        'course': course,
        'previous_page': previous_page,
        'next_page': next_page,
        'like_count': CourseInteraction.objects.filter(course_page=page, liked=True).count(),
        'user_has_liked': CourseInteraction.objects.filter(course_page=page, user=request.user, liked=True).exists() if request.user.is_authenticated else False,
        'comments': CourseComment.objects.filter(course_page=page).order_by('-created_at')
    }
    
    return render(request, "coursepage.html", context)


def qrgen(request):
    # Check if user is a learner
    if not hasattr(request.user, 'userdetail') or request.user.userdetail.role.lower() != 'learner':
        messages.error(request, "Only learners can access this page.")
        return redirect('dashboard')
    
    # Get all courses the learner is enrolled in
    enrolled_courses = request.user.enrolled_courses.all()
    
    # Prepare course data with QR codes
    courses_with_qr = []
    for course in enrolled_courses:
        # Get or create QR code for each course
        qr_code, created = QRcode.objects.get_or_create(
            course=course,
            defaults={
                'qrcode_url': f"{request.build_absolute_uri('/')}elevatelearning/continue/{course.course_id}/"
            }
        )
        courses_with_qr.append({
            'course': course,
            'qr_code': qr_code,
            'enrollment_date': course.enrollment_date if hasattr(course, 'enrollment_date') else None
        })
    
    context = {
        'enrolled_courses': courses_with_qr
    }
    return render(request, "qrgen.html", context)

def login_view(request):
    if request.method == 'POST':
        email = request.POST.get('email')
        password = request.POST.get('password')
        role = request.POST.get('user-role')  # This comes from the hidden input in your form
        
        # Authenticate the user
        user = authenticate(request, username=email, password=password)
        
        if user is not None:
            try:
                # Check if the user has the correct role
                user_detail = UserDetail.objects.get(user=user)
                
                if user_detail.role.lower() == role.lower():
                    login(request, user)
                    next_url = request.GET.get('next')
                    if next_url:
                        return redirect(next_url)
                    
                    # Redirect based on role
                    if role.lower() == 'educator':
                        return redirect('coursecreate')
                    else:
                        return redirect('dashboard')
                else:
                    messages.error(request, f"Please login as a {user_detail.role} using the {user_detail.role} login option.")
            except UserDetail.DoesNotExist:
                messages.error(request, "User details not found. Please contact support.")
        else:
            messages.error(request, "Invalid email or password.")
    
    # If GET request or authentication failed, render the login page
    return render(request, "login.html")

def register(request):
    if request.method == 'POST':
        try:
            # Get form data
            email = request.POST.get('email')
            firstname = request.POST.get('firstname')
            surname = request.POST.get('surname')
            mobile_no = request.POST.get('mobile_no', '')  # Optional field
            password1 = request.POST.get('password1')
            password2 = request.POST.get('password2')
            role = request.POST.get('role')  # Default to learner if not provided

            # Validate data
            if not all([email, firstname, surname, password1, password2]):
                raise ValidationError("All required fields must be filled.")
            
            if password1 != password2:
                raise ValidationError("Passwords don't match.")
            
            if User.objects.filter(email=email).exists():
                raise ValidationError("Email already exists.")
            
            # Create User
            user = User.objects.create(
                username=email,  # Using email as username
                email=email,
                password=make_password(password1),
                first_name=firstname,
                last_name=surname,
            )
            
            # Create UserDetail
            UserDetail.objects.create(
                user=user,
                firstname=firstname,
                surname=surname,
                mobile_no=mobile_no,
                role=role,
                email=email
            )
            
            # Authenticate and login the user
            user = authenticate(request, username=email, password=password1)
            if user is not None:
                login(request, user)
                # Redirect based on role
                if role == 'educator':
                    return redirect('coursecreate')
                else:
                    return redirect('dashboard')
            
        except ValidationError as e:
            messages.error(request, str(e))
        except Exception as e:
            messages.error(request, f"An error occurred: {str(e)}")
    
    # If GET request or form submission failed, render the registration page
    return render(request, "register.html")

@login_required
def mycourse(request):
    # Check if user is a learner
    if not hasattr(request.user, 'userdetail') or request.user.userdetail.role.lower() != 'learner':
        messages.error(request, "Only learners can access this page.")
        return redirect('dashboard')
    
    # Get all courses the learner is enrolled in
    enrolled_courses = request.user.enrolled_courses.all()
    
    # Get progress for each course
     # Get progress for each course - MODIFIED THIS PART
    courses_with_progress = []
    for course in enrolled_courses:
        try:
            progress = CourseProgress.objects.get(learner=request.user, course__course_id=course.course_id)
            next_page = progress.get_next_incomplete_page()
            progress_percentage = progress.progress_percentage * 100
        except CourseProgress.DoesNotExist:
            progress = None
            next_page = course.pages.order_by('page_no').first()
            progress_percentage = 0
        
        courses_with_progress.append({
            'course': course,
            'progress': progress,
            'next_page': next_page,
            'progress_percentage': progress_percentage,
            'is_completed': progress_percentage == 100 if progress else False
        })
    
    # Get all available courses that the learner hasn't enrolled in
    available_courses = Course.objects.exclude(learners=request.user)
    
    context = {
        'enrolled_courses': courses_with_progress,
        'available_courses': available_courses
    }
    return render(request, "mycourse.html", context)

@login_required
def enroll_course(request, course_id):
    if not hasattr(request.user, 'userdetail') or request.user.userdetail.role.lower() != 'learner':
        messages.error(request, "Only learners can enroll in courses.")
        return redirect('dashboard')
    
    course = get_object_or_404(Course, course_id=course_id)
    
    # Check if already enrolled
    if request.user.enrolled_courses.filter(pk=course_id).exists():
        messages.warning(request, f"You are already enrolled in {course.title}.")
        return redirect('mycourse')
    
    # Enroll the learner
    course.learners.add(request.user)
    
    # Create a progress record
    CourseProgress.objects.create(
        learner=request.user,
        course=course,
        current_page=course.pages.order_by('page_no').first()
    )
    
    messages.success(request, f"Successfully enrolled in {course.title}!")
    return redirect('mycourse')


def continue_course(request, course_id):
    if not hasattr(request.user, 'userdetail') or request.user.userdetail.role.lower() != 'learner':
        messages.error(request, "Only learners can access courses.")
        redirect_url = request.path
        login_url = f"{reverse('login')}?{urlencode({'next': redirect_url})}"
        return redirect(login_url)
    
    course = get_object_or_404(Course, course_id=course_id)
    
    # Check if enrolled
    if not request.user.enrolled_courses.filter(course_id=course.course_id).exists():
        messages.error(request, "You need to enroll in this course first.")
        return redirect('mycourse')
    
    # Get or create progress
    progress, created = CourseProgress.objects.get_or_create(
        learner=request.user,
        course=course,
        defaults={'current_page': course.pages.order_by('page_no').first()}
    )
    
    # Redirect to the current page
    if progress.current_page:
        return redirect('coursepage', coursepage_id=progress.current_page.coursepage_id)
    else:
        first_page = course.pages.order_by('page_no').first()
        if first_page:
            progress.current_page = first_page
            progress.save()
            return redirect('coursepage', page_id=first_page.coursepage_id)
        else:
            messages.error(request, "This course has no content yet.")
            return redirect('mycourse')


@login_required
def createdcourses(request):
    # Get all courses created by the current user (educator)
    courses = Course.objects.filter(creator=request.user).order_by('-created_date')
    
    context = {
        'courses': courses
    }
    return render(request, "createdcourses.html", context)

@login_required
def addpage(request, course_id):
    # Get the course or return 404 if not found
    course = get_object_or_404(Course, pk=course_id, creator=request.user)

    if request.method == 'POST':
        if 'delete_page' in request.POST:
            # Handle page deletion
            page_id = request.POST.get('page_id')
            page = get_object_or_404(CoursePage, pk=page_id, course=course)
            page.delete()
            
            # Reorder remaining pages
            pages = CoursePage.objects.filter(course=course).order_by('page_no')
            for index, page in enumerate(pages, start=1):
                if page.page_no != index:
                    page.page_no = index
                    page.save()
            
            messages.success(request, "Page deleted successfully!")
            return redirect('addpage', course_id=course_id)
        elif 'delete_course' in request.POST:
            # Handle course deletion
            course_title = course.title
            course.delete()
            messages.success(request, f"Course '{course_title}' deleted successfully!")
            return redirect('createdcourses')    

    
    # Get all pages for this course ordered by page number
    pages = CoursePage.objects.filter(course=course).order_by('page_no')
    
    context = {
        'course': course,
        'pages': pages
    }
    return render(request, "addpage.html", context)

@login_required
def newpage(request, course_id, coursepage_id=None):
    # Get the course or return 404 if not found
    course = get_object_or_404(Course, pk=course_id, creator=request.user)
    page = None

    if coursepage_id:
        page = get_object_or_404(CoursePage, coursepage_id=coursepage_id)
    
    if request.method == 'POST':
        # Get form data
        page_title = request.POST.get('title')
        page_description = request.POST.get('content')
        
        if not all([page_title, page_description]):
            messages.error(request, "Please fill all required fields.")
            return redirect('newpage', course_id=course_id)
        
        try:
            if page:
                # Update existing page
                page.page_title = page_title
                page.page_description = page_description
                page.save()
                messages.success(request, f"Page '{page_title}' updated successfully!")
            else:
                # Create new page
                page = CoursePage.objects.create(
                    course=course,
                    page_title=page_title,
                    page_description=page_description
                )
                messages.success(request, f"Page '{page_title}' created successfully!")
            
            return redirect('addpage', course_id=course_id)
        except Exception as e:
            messages.error(request, f"Error: {str(e)}")
            return redirect('newpage', course_id=course_id, coursepage_id=coursepage_id) if coursepage_id else redirect('newpage', course_id=course_id)
    
    # For GET requests, show the form
    context = {
        'course': course,
        'page': page,
        'is_edit': coursepage_id is not None
    }
    return render(request, "newpage.html", context)


@require_POST
def toggle_like(request, coursepage_id):
    page = get_object_or_404(CoursePage, coursepage_id=coursepage_id)
    interaction, created = CourseInteraction.objects.get_or_create(
        course_page=page,
        user=request.user
    )
    interaction.liked = not interaction.liked
    interaction.save()
    messages.success(request, "Like updated successfully!")
    return redirect('coursepage', coursepage_id=coursepage_id)

@require_POST
def add_comment(request, coursepage_id):
    page = get_object_or_404(CoursePage, coursepage_id=coursepage_id)
    text = request.POST.get('text', '').strip()
    if text:
        CourseComment.objects.create(
            course_page=page,
            user=request.user,
            text=text
        )
        messages.success(request, "Comment added successfully!")
    else:
        messages.error(request, "Comment cannot be empty.")
    return redirect('coursepage', coursepage_id=coursepage_id)

@require_POST
def record_share(request, coursepage_id):
    page = get_object_or_404(CoursePage, coursepage_id=coursepage_id)
    interaction, created = CourseInteraction.objects.get_or_create(
        course_page=page,
        user=request.user
    )
    interaction.shared = True
    interaction.save()
    messages.success(request, "Share recorded successfully!")
    return redirect(request.META.get('HTTP_REFERER', 'coursepage'))

def certificate_view(request, course_id):
    course = get_object_or_404(Course, course_id=course_id)
    
    
    context = {
        'course': course,
        'completion_date': timezone.now(),
        'certificate_id': str(uuid.uuid4())[:8].upper(),  # Generate a short unique ID
    }
    return render(request, "viewcertificate.html", context)