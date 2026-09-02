"""
Budgeto API Serializers.

Handles serialization/deserialization for all models,
including nested representations and computed fields.
"""
from rest_framework import serializers
from django.contrib.auth import get_user_model
from django.contrib.auth.password_validation import validate_password
from .models import Account, Category, Transaction, Budget, Goal, RecurringTransaction, MonthlyPlan, Household, Project, ProjectMilestone

User = get_user_model()


class HouseholdSerializer(serializers.ModelSerializer):
    class Meta:
        model = Household
        fields = ['id', 'name', 'created_at']
        read_only_fields = ['id', 'created_at']


# ──────────────────────────────────────────────
# Auth Serializers
# ──────────────────────────────────────────────

class RegisterSerializer(serializers.ModelSerializer):
    """Serializer for user registration."""
    password = serializers.CharField(write_only=True, min_length=6)
    name = serializers.CharField(source='first_name')

    class Meta:
        model = User
        fields = ['id', 'name', 'email', 'password', 'currency', 'created_at']
        read_only_fields = ['id', 'created_at']

    def create(self, validated_data):
        password = validated_data.pop('password')
        # Use email as username too
        validated_data['username'] = validated_data['email']
        user = User(**validated_data)
        user.set_password(password)
        user.save()
        return user


class LoginSerializer(serializers.Serializer):
    """Serializer for user login."""
    email = serializers.EmailField()
    password = serializers.CharField()


class UserSerializer(serializers.ModelSerializer):
    """Serializer for reading/updating user profile."""
    name = serializers.CharField(source='first_name')
    household_detail = HouseholdSerializer(source='household', read_only=True)

    class Meta:
        model = User
        fields = ['id', 'name', 'email', 'currency', 'household', 'household_detail', 'created_at']
        read_only_fields = ['id', 'email', 'household_detail', 'created_at']


# ──────────────────────────────────────────────
# Account Serializers
# ──────────────────────────────────────────────

class AccountSerializer(serializers.ModelSerializer):
    """Serializer for financial accounts."""

    class Meta:
        model = Account
        fields = ['id', 'user', 'name', 'type', 'balance', 'icon', 'color', 'created_at']
        read_only_fields = ['id', 'user', 'created_at']

    def create(self, validated_data):
        validated_data['user'] = self.context['request'].user
        return super().create(validated_data)


# ──────────────────────────────────────────────
# Category Serializers
# ──────────────────────────────────────────────

class CategorySerializer(serializers.ModelSerializer):
    """Serializer for transaction categories."""

    class Meta:
        model = Category
        fields = ['id', 'name', 'icon', 'color', 'type']


# ──────────────────────────────────────────────
# Transaction Serializers
# ──────────────────────────────────────────────

class TransactionReadSerializer(serializers.ModelSerializer):
    """Serializer for reading transactions (includes category info)."""
    category_name = serializers.CharField(source='category.name', read_only=True)
    category_icon = serializers.CharField(source='category.icon', read_only=True)
    category_color = serializers.CharField(source='category.color', read_only=True)

    class Meta:
        model = Transaction
        fields = [
            'id', 'user', 'amount', 'type', 'category', 'account',
            'description', 'date', 'created_at',
            'category_name', 'category_icon', 'category_color',
        ]


class TransactionWriteSerializer(serializers.ModelSerializer):
    """Serializer for creating/updating transactions."""

    class Meta:
        model = Transaction
        fields = ['id', 'user', 'amount', 'type', 'category', 'account', 'description', 'date', 'created_at']
        read_only_fields = ['id', 'user', 'created_at']

    def create(self, validated_data):
        validated_data['user'] = self.context['request'].user
        return super().create(validated_data)


# ──────────────────────────────────────────────
# Budget Serializers
# ──────────────────────────────────────────────

class BudgetReadSerializer(serializers.ModelSerializer):
    """Serializer for reading budgets (includes computed spent, category info)."""
    category_name = serializers.CharField(source='category.name', read_only=True)
    category_icon = serializers.CharField(source='category.icon', read_only=True)
    category_color = serializers.CharField(source='category.color', read_only=True)
    spent = serializers.FloatField(read_only=True)
    percentage = serializers.FloatField(read_only=True)
    remaining = serializers.FloatField(read_only=True)

    class Meta:
        model = Budget
        fields = [
            'id', 'user', 'category', 'amount', 'month', 'year',
            'category_name', 'category_icon', 'category_color',
            'spent', 'percentage', 'remaining',
        ]


class BudgetWriteSerializer(serializers.ModelSerializer):
    """Serializer for creating/updating budgets."""

    class Meta:
        model = Budget
        fields = ['id', 'category', 'amount', 'month', 'year']
        read_only_fields = ['id']

    def create(self, validated_data):
        validated_data['user'] = self.context['request'].user
        # Upsert logic: update if exists, create if not
        budget, created = Budget.objects.update_or_create(
            user=validated_data['user'],
            category=validated_data['category'],
            month=validated_data['month'],
            year=validated_data['year'],
            defaults={'amount': validated_data['amount']},
        )
        return budget


# ──────────────────────────────────────────────
# Goal Serializers
# ──────────────────────────────────────────────

class GoalSerializer(serializers.ModelSerializer):
    """Serializer for savings goals."""
    percentage = serializers.FloatField(read_only=True)
    remaining = serializers.FloatField(read_only=True)
    is_completed = serializers.BooleanField(read_only=True)

    class Meta:
        model = Goal
        fields = [
            'id', 'user', 'title', 'target_amount', 'current_amount',
            'deadline', 'image_key', 'created_at',
            'percentage', 'remaining', 'is_completed',
        ]
        read_only_fields = ['id', 'user', 'created_at']

    def create(self, validated_data):
        validated_data['user'] = self.context['request'].user
        return super().create(validated_data)


class GoalContributionSerializer(serializers.Serializer):
    """Serializer for adding a contribution to a goal."""
    amount = serializers.DecimalField(max_digits=15, decimal_places=2, min_value=0)


# ──────────────────────────────────────────────
# Recurring Transaction Serializers
# ──────────────────────────────────────────────

class RecurringTransactionReadSerializer(serializers.ModelSerializer):
    """Serializer for reading recurring transactions."""
    category_name = serializers.CharField(source='category.name', read_only=True)
    category_icon = serializers.CharField(source='category.icon', read_only=True)
    category_color = serializers.CharField(source='category.color', read_only=True)

    class Meta:
        model = RecurringTransaction
        fields = [
            'id', 'user', 'amount', 'type', 'category', 'account',
            'description', 'period', 'start_date', 'next_date', 'created_at',
            'category_name', 'category_icon', 'category_color',
        ]


class RecurringTransactionWriteSerializer(serializers.ModelSerializer):
    """Serializer for creating recurring transactions."""

    class Meta:
        model = RecurringTransaction
        fields = ['id', 'amount', 'type', 'category', 'account', 'description', 'period', 'start_date']
        read_only_fields = ['id']

    def create(self, validated_data):
        validated_data['user'] = self.context['request'].user
        validated_data['next_date'] = validated_data['start_date']
        rt = RecurringTransaction(**validated_data)
        rt.next_date = rt.calculate_next_date()
        rt.save()
        return rt


# ──────────────────────────────────────────────
# Monthly Plan Serializers
# ──────────────────────────────────────────────

class MonthlyPlanSerializer(serializers.ModelSerializer):
    """Serializer for monthly plans."""

    class Meta:
        model = MonthlyPlan
        fields = ['id', 'user', 'month', 'year', 'needs', 'expectations', 'created_at']
        read_only_fields = ['id', 'user', 'created_at']

    def create(self, validated_data):
        validated_data['user'] = self.context['request'].user
        # Upsert logic
        plan, created = MonthlyPlan.objects.update_or_create(
            user=validated_data['user'],
            month=validated_data['month'],
            year=validated_data['year'],
            defaults={
                'needs': validated_data['needs'],
                'expectations': validated_data['expectations'],
            },
        )
        return plan


# ──────────────────────────────────────────────
# Summary Serializers (for custom endpoints)
# ──────────────────────────────────────────────

class MonthlySummarySerializer(serializers.Serializer):
    """Serializer for monthly income/expense summary."""
    income = serializers.FloatField()
    expense = serializers.FloatField()
    balance = serializers.FloatField()


class CategoryExpenseSerializer(serializers.Serializer):
    """Serializer for expense breakdown by category."""
    id = serializers.CharField()
    name = serializers.CharField()
    icon = serializers.CharField()
    color = serializers.CharField()
    total = serializers.FloatField()


class DailyTotalSerializer(serializers.Serializer):
    """Serializer for daily totals."""
    day = serializers.CharField()
    total = serializers.FloatField()


class WeeklyTotalSerializer(serializers.Serializer):
    """Serializer for weekly totals."""
    week = serializers.CharField()
    total = serializers.FloatField()


class BudgetSummarySerializer(serializers.Serializer):
    """Serializer for budget summary."""
    total = serializers.FloatField()
    spent = serializers.FloatField()
    remaining = serializers.FloatField()


# ──────────────────────────────────────────────
# Project Serializers
# ──────────────────────────────────────────────

class ProjectMilestoneSerializer(serializers.ModelSerializer):
    """Serializer for project milestones."""
    percentage = serializers.FloatField(read_only=True)
    is_completed = serializers.BooleanField(read_only=True)

    class Meta:
        model = ProjectMilestone
        fields = [
            'id', 'project', 'title', 'description',
            'target_amount', 'current_amount', 'status',
            'due_date', 'order', 'created_at',
            'percentage', 'is_completed',
        ]
        read_only_fields = ['id', 'created_at']


class ProjectReadSerializer(serializers.ModelSerializer):
    """Serializer for reading projects (includes nested milestones)."""
    milestones = ProjectMilestoneSerializer(many=True, read_only=True)
    percentage = serializers.FloatField(read_only=True)
    remaining = serializers.FloatField(read_only=True)
    is_completed = serializers.BooleanField(read_only=True)
    milestone_count = serializers.IntegerField(read_only=True)
    completed_milestones = serializers.IntegerField(read_only=True)

    class Meta:
        model = Project
        fields = [
            'id', 'user', 'title', 'description',
            'target_amount', 'current_amount', 'status',
            'start_date', 'end_date', 'color', 'icon',
            'created_at', 'milestones',
            'percentage', 'remaining', 'is_completed',
            'milestone_count', 'completed_milestones',
        ]


class ProjectWriteSerializer(serializers.ModelSerializer):
    """Serializer for creating/updating projects."""

    class Meta:
        model = Project
        fields = [
            'id', 'title', 'description',
            'target_amount', 'current_amount', 'status',
            'start_date', 'end_date', 'color', 'icon', 'created_at',
        ]
        read_only_fields = ['id', 'created_at']

    def create(self, validated_data):
        validated_data['user'] = self.context['request'].user
        return super().create(validated_data)


class ProjectContributionSerializer(serializers.Serializer):
    """Serializer for adding a contribution to a project."""
    amount = serializers.DecimalField(max_digits=15, decimal_places=2, min_value=0)

