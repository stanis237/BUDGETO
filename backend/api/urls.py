"""
Budgeto API URL Configuration.
"""
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from rest_framework_simplejwt.views import TokenRefreshView

from .views import (
    RegisterView, LoginView, MeView,
    AccountViewSet, CategoryViewSet, TransactionViewSet,
    BudgetViewSet, GoalViewSet, RecurringTransactionViewSet,
    MonthlyPlanViewSet, export_csv, export_pdf, HouseholdViewSet,
    ProjectViewSet, ProjectMilestoneViewSet,
)
from .ai_views import ai_chat, scan_receipt
from .analytics_views import budget_forecast, detect_subscriptions
from .gamification_views import list_challenges, list_badges

router = DefaultRouter()
router.register(r'accounts', AccountViewSet, basename='account')
router.register(r'categories', CategoryViewSet, basename='category')
router.register(r'transactions', TransactionViewSet, basename='transaction')
router.register(r'budgets', BudgetViewSet, basename='budget')
router.register(r'goals', GoalViewSet, basename='goal')
router.register(r'recurring-transactions', RecurringTransactionViewSet, basename='recurring-transaction')
router.register(r'monthly-plans', MonthlyPlanViewSet, basename='monthly-plan')
router.register(r'households', HouseholdViewSet, basename='household')
router.register(r'projects', ProjectViewSet, basename='project')
router.register(r'project-milestones', ProjectMilestoneViewSet, basename='project-milestone')

urlpatterns = [
    # Auth
    path('auth/register/', RegisterView.as_view(), name='register'),
    path('auth/login/', LoginView.as_view(), name='login'),
    path('auth/refresh/', TokenRefreshView.as_view(), name='token-refresh'),
    path('auth/me/', MeView.as_view(), name='me'),

    # Export
    path('export/csv/', export_csv, name='export-csv'),
    path('export/pdf/', export_pdf, name='export-pdf'),

    # AI Features
    path('ai/chat/', ai_chat, name='ai-chat'),
    path('ai/scan-receipt/', scan_receipt, name='ai-scan-receipt'),

    # Advanced Analytics
    path('analytics/forecast/', budget_forecast, name='analytics-forecast'),
    path('analytics/subscriptions/', detect_subscriptions, name='analytics-subscriptions'),

    # Gamification
    path('gamification/challenges/', list_challenges, name='gamification-challenges'),
    path('gamification/badges/', list_badges, name='gamification-badges'),

    # Router (all CRUD endpoints)
    path('', include(router.urls)),
]
