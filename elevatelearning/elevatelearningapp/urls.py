from django.urls import path
from . import views


urlpatterns = [
    path("home/", views.index, name="index"),
    path("dashboard/", views.dashboard, name="dashboard"),
    path("coursecreate/", views.coursecreate, name="coursecreate"),
    path("coursepage/<int:coursepage_id>/", views.coursepage, name="coursepage"),
    path('coursepage/<int:coursepage_id>/like/', views.toggle_like, name='toggle_like'),
    path('coursepage/<int:coursepage_id>/comment/', views.add_comment, name='add_comment'),
    path('coursepage/<int:coursepage_id>/share/', views.record_share, name='record_share'),
    path("qrgen/", views.qrgen, name="qrgen"),
    path('login/', views.login_view, name='login'),
    path('logout/', views.logout_view, name='logout'),
    path('register/', views.register, name='register'),
    path('mycourse/', views.mycourse, name='mycourse'),
    path('createdcourses/', views.createdcourses, name='createdcourses'),
    path('course/<int:course_id>/pages/', views.addpage, name='addpage'),
    path('course/<int:course_id>/pages/new/', views.newpage, name='newpage'),
    path('course/<int:course_id>/pages/<int:coursepage_id>/edit/', views.newpage, name='newpage'),
    path('enroll/<int:course_id>/', views.enroll_course, name='enroll_course'),
    path('continue/<int:course_id>/', views.continue_course, name='continue_course'),
    path('certificate/<int:course_id>/', views.certificate_view, name='certificate'),
]