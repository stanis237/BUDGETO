"""
Budgeto API Admin Configuration.
"""
from django.contrib import admin
from django.contrib.auth import get_user_model
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from .models import Account, Category, Transaction, Budget, Goal, RecurringTransaction, MonthlyPlan

User = get_user_model()


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    list_display = ['email', 'first_name', 'currency', 'date_joined', 'is_active']
    list_filter = ['is_active', 'currency', 'date_joined']
    search_fields = ['email', 'first_name']
    ordering = ['-date_joined']

    fieldsets = BaseUserAdmin.fieldsets + (
        ('Budgeto', {'fields': ('currency',)}),
    )


@admin.register(Account)
class AccountAdmin(admin.ModelAdmin):
    list_display = ['name', 'user', 'type', 'balance', 'created_at']
    list_filter = ['type']
    search_fields = ['name', 'user__email']


@admin.register(Category)
class CategoryAdmin(admin.ModelAdmin):
    list_display = ['id', 'name', 'icon', 'type', 'color']
    list_filter = ['type']
    search_fields = ['name']


@admin.register(Transaction)
class TransactionAdmin(admin.ModelAdmin):
    list_display = ['date', 'user', 'type', 'amount', 'category', 'description']
    list_filter = ['type', 'date', 'category']
    search_fields = ['description', 'user__email']
    date_hierarchy = 'date'


@admin.register(Budget)
class BudgetAdmin(admin.ModelAdmin):
    list_display = ['user', 'category', 'amount', 'month', 'year']
    list_filter = ['month', 'year']
    search_fields = ['user__email', 'category__name']


@admin.register(Goal)
class GoalAdmin(admin.ModelAdmin):
    list_display = ['title', 'user', 'target_amount', 'current_amount', 'deadline', 'is_completed']
    list_filter = ['deadline']
    search_fields = ['title', 'user__email']

    def is_completed(self, obj):
        return obj.is_completed
    is_completed.boolean = True


@admin.register(RecurringTransaction)
class RecurringTransactionAdmin(admin.ModelAdmin):
    list_display = ['user', 'type', 'amount', 'category', 'period', 'next_date']
    list_filter = ['type', 'period']
    search_fields = ['user__email', 'description']


@admin.register(MonthlyPlan)
class MonthlyPlanAdmin(admin.ModelAdmin):
    list_display = ['user', 'month', 'year', 'needs', 'expectations']
    list_filter = ['month', 'year']
    search_fields = ['user__email']
