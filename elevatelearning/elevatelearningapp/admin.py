from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from django.contrib.auth.models import User
from django.utils.html import format_html
from .models import UserDetail, Course, QRcode, CoursePage, CourseProgress, CourseInteraction, CourseComment

# Inline Admin for UserDetail
class UserDetailInline(admin.StackedInline):
    model = UserDetail
    can_delete = False
    verbose_name_plural = 'User Details'
    fields = ('firstname', 'surname', 'mobile_no', 'role', 'email', 'is_archived')
    readonly_fields = ('email',)

# Extend User Admin
class CustomUserAdmin(UserAdmin):
    inlines = (UserDetailInline,)
    list_display = ('username', 'email', 'first_name', 'last_name', 'get_role', 'is_staff', 'is_active')
    list_editable = ('is_active', 'is_staff')
    list_filter = ('is_staff', 'is_superuser', 'is_active', 'userdetail__role')
    search_fields = ('username', 'first_name', 'last_name', 'email', 'userdetail__role')

    def get_role(self, obj):
        return obj.userdetail.role if hasattr(obj, 'userdetail') else '-'
    get_role.short_description = 'Role'

# Custom Actions
def archive_selected(modeladmin, request, queryset):
    queryset.update(is_archived=True)
archive_selected.short_description = "Archive selected items"

def unarchive_selected(modeladmin, request, queryset):
    queryset.update(is_archived=False)
unarchive_selected.short_description = "Unarchive selected items"

def delete_selected(modeladmin, request, queryset):
    queryset.delete()
delete_selected.short_description = "Delete selected items"

# ModelAdmin Classes
@admin.register(Course)
class CourseAdmin(admin.ModelAdmin):
    list_display = ('title', 'category', 'creator_link', 'learner_count', 'page_count', 
                   'is_archived', 'created_date')
    list_editable = ('category', 'is_archived')
    list_filter = ('is_archived', 'category', 'created_date')
    search_fields = ('title', 'description', 'creator__username')
    actions = [delete_selected, archive_selected, unarchive_selected]
    readonly_fields = ('created_date', 'modified_date', 'course_id')
    filter_horizontal = ('learners',)
    list_per_page = 20
    raw_id_fields = ('creator',)
    
    fieldsets = (
        ('Basic Information', {
            'fields': ('course_id', 'title', 'description', 'category')
        }),
        ('Relationships', {
            'fields': ('creator', 'learners')
        }),
        ('Status', {
            'fields': ('is_archived',)
        }),
        ('Timestamps', {
            'fields': ('created_date', 'modified_date')
        }),
    )

    def creator_link(self, obj):
        return format_html('<a href="{}">{}</a>', 
                         f'/admin/auth/user/{obj.creator.id}/change/',
                         obj.creator.username)
    creator_link.short_description = 'Creator'

    def learner_count(self, obj):
        return obj.learners.count()
    learner_count.short_description = 'Learners'

    def page_count(self, obj):
        return obj.pages.count()
    page_count.short_description = 'Pages'

@admin.register(CoursePage)
class CoursePageAdmin(admin.ModelAdmin):
    list_display = ('page_title', 'course_link', 'page_no', 'is_completed', 
                   'is_archived', 'created_at', 'comment_count')
    list_editable = ('page_no', 'is_completed', 'is_archived')
    list_filter = ('is_archived', 'is_completed', 'course', 'created_at')
    search_fields = ('page_title', 'page_description', 'course__title')
    actions = [delete_selected, archive_selected, unarchive_selected]
    list_per_page = 20
    raw_id_fields = ('course',)
    
    def course_link(self, obj):
        return format_html('<a href="{}">{}</a>', 
                         f'/admin/elearning/course/{obj.course.course_id}/change/',
                         obj.course.title)
    course_link.short_description = 'Course'
    course_link.admin_order_field = 'course'

    def comment_count(self, obj):
        return obj.comments.count()
    comment_count.short_description = 'Comments'

@admin.register(QRcode)
class QRcodeAdmin(admin.ModelAdmin):
    list_display = ('qrcode_id', 'course_link', 'short_qrcode_url', 'created_at', 'is_archived')
    list_editable = ('is_archived',)
    list_filter = ('is_archived', 'created_at')
    search_fields = ('qrcode_url', 'course__title')
    actions = [delete_selected, archive_selected, unarchive_selected]
    readonly_fields = ('qrcode_id', 'created_at', 'modified_at')
    raw_id_fields = ('course',)
    
    def course_link(self, obj):
        return format_html('<a href="{}">{}</a>', 
                         f'/admin/elearning/course/{obj.course.course_id}/change/',
                         obj.course.title)
    course_link.short_description = 'Course'

    def short_qrcode_url(self, obj):
        return obj.qrcode_url[:50] + '...' if len(obj.qrcode_url) > 50 else obj.qrcode_url
    short_qrcode_url.short_description = 'QR Code URL'

@admin.register(CourseProgress)
class CourseProgressAdmin(admin.ModelAdmin):
    list_display = ('learner_link', 'course_link', 'progress_bar', 'current_page_link', 
                   'started_at', 'get_is_completed', 'is_archived')
    list_editable = ('is_archived',)
    list_filter = ('is_archived', 'course', 'started_at')
    search_fields = ('learner__username', 'course__title')
    actions = [delete_selected, archive_selected, unarchive_selected]
    readonly_fields = ('started_at', 'completed_at', 'last_updated')
    list_per_page = 20
    raw_id_fields = ('learner', 'course', 'current_page')
    
    def learner_link(self, obj):
        return format_html('<a href="{}">{}</a>', 
                         f'/admin/auth/user/{obj.learner.id}/change/',
                         obj.learner.username)
    learner_link.short_description = 'Learner'

    def course_link(self, obj):
        return format_html('<a href="{}">{}</a>', 
                         f'/admin/elearning/course/{obj.course.course_id}/change/',
                         obj.course.title)
    course_link.short_description = 'Course'

    def current_page_link(self, obj):
        if obj.current_page:
            return format_html('<a href="{}">{}</a>', 
                             f'/admin/elearning/coursepage/{obj.current_page.coursepage_id}/change/',
                             obj.current_page.page_title)
        return '-'
    current_page_link.short_description = 'Current Page'

    def progress_bar(self, obj):
        percentage = obj.progress_percentage * 100
        return format_html(
            '<div style="width:100px;background:#ddd;border-radius:5px;">'
            '<div style="width:{}%;background:#4CAF50;height:20px;border-radius:5px;text-align:center;color:white;">{}%</div>'
            '</div>', percentage, int(percentage))
    progress_bar.short_description = 'Progress'

    def get_is_completed(self, obj):
        return obj.is_completed
    get_is_completed.boolean = True
    get_is_completed.short_description = 'Completed'

@admin.register(CourseInteraction)
class CourseInteractionAdmin(admin.ModelAdmin):
    list_display = ('user_link', 'course_page_link', 'liked', 'shared', 'created_at', 'is_archived')
    list_editable = ('liked', 'shared', 'is_archived')
    list_filter = ('is_archived', 'liked', 'shared', 'created_at')
    search_fields = ('user__username', 'course_page__page_title')
    actions = [delete_selected, archive_selected, unarchive_selected]
    readonly_fields = ('created_at',)
    raw_id_fields = ('user', 'course_page')
    
    def user_link(self, obj):
        return format_html('<a href="{}">{}</a>', 
                         f'/admin/auth/user/{obj.user.id}/change/',
                         obj.user.username)
    user_link.short_description = 'User'

    def course_page_link(self, obj):
        return format_html('<a href="{}">{}</a>', 
                         f'/admin/elearning/coursepage/{obj.course_page.coursepage_id}/change/',
                         obj.course_page.page_title)
    course_page_link.short_description = 'Course Page'

@admin.register(CourseComment)
class CourseCommentAdmin(admin.ModelAdmin):
    list_display = ('user_link', 'course_page_link', 'short_text', 'created_at', 'is_archived')
    list_editable = ('is_archived',)
    list_filter = ('is_archived', 'created_at')
    search_fields = ('user__username', 'text', 'course_page__page_title')
    actions = [delete_selected, archive_selected, unarchive_selected]
    readonly_fields = ('created_at', 'updated_at')
    raw_id_fields = ('user', 'course_page')
    
    def user_link(self, obj):
        return format_html('<a href="{}">{}</a>', 
                         f'/admin/auth/user/{obj.user.id}/change/',
                         obj.user.username)
    user_link.short_description = 'User'

    def course_page_link(self, obj):
        return format_html('<a href="{}">{}</a>', 
                         f'/admin/elearning/coursepage/{obj.course_page.coursepage_id}/change/',
                         obj.course_page.page_title)
    course_page_link.short_description = 'Course Page'

    def short_text(self, obj):
        return obj.text[:50] + '...' if len(obj.text) > 50 else obj.text
    short_text.short_description = 'Comment'

# Unregister the default User admin and register our custom one
admin.site.unregister(User)
admin.site.register(User, CustomUserAdmin)

# Admin Site Customization
admin.site.site_header = "Elevate Learning Administration"
admin.site.site_title = "Elevate Learning Admin Portal"
admin.site.index_title = "Welcome to Elevate Learning Admin"