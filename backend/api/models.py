"""
Budgeto API Models.

Reproduces all 8 data models from the Flutter app:
User, Account, Category, Transaction, Budget, Goal, RecurringTransaction, MonthlyPlan.
"""
import uuid
from django.contrib.auth.models import AbstractUser
from django.db import models
from django.core.validators import MinValueValidator


class Household(models.Model):
    """
    A Household represents a group of users sharing budgets, accounts, and transactions.
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=150)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'households'

    def __str__(self):
        return self.name


class User(AbstractUser):
    """
    Custom user model extending Django's AbstractUser.
    Maps to Flutter's UserModel.
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    currency = models.CharField(max_length=10, default='EUR')
    household = models.ForeignKey(Household, on_delete=models.SET_NULL, null=True, blank=True, related_name='members')
    created_at = models.DateTimeField(auto_now_add=True)

    # Override email to make it unique and required
    email = models.EmailField(unique=True)

    # Use email for authentication instead of username
    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['username', 'first_name']

    class Meta:
        db_table = 'users'
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.first_name} ({self.email})"


class Account(models.Model):
    """
    Financial account (cash, bank, mobile_money, card).
    Maps to Flutter's AccountModel.
    """
    ACCOUNT_TYPES = [
        ('cash', 'Espèces'),
        ('bank', 'Banque'),
        ('mobile_money', 'Mobile Money'),
        ('card', 'Carte'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='accounts')
    name = models.CharField(max_length=100)
    type = models.CharField(max_length=20, choices=ACCOUNT_TYPES)
    balance = models.DecimalField(max_digits=15, decimal_places=2, default=0)
    icon = models.CharField(max_length=50, blank=True, null=True)
    color = models.CharField(max_length=20)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'accounts'
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.name} ({self.get_type_display()})"


class Category(models.Model):
    """
    Transaction category (income or expense).
    Maps to Flutter's CategoryModel.
    """
    CATEGORY_TYPES = [
        ('income', 'Revenu'),
        ('expense', 'Dépense'),
    ]

    id = models.CharField(primary_key=True, max_length=50)
    name = models.CharField(max_length=100)
    icon = models.CharField(max_length=50)
    color = models.CharField(max_length=20)
    type = models.CharField(max_length=10, choices=CATEGORY_TYPES)

    class Meta:
        db_table = 'categories'
        verbose_name_plural = 'categories'
        ordering = ['name']

    def __str__(self):
        return f"{self.name} ({self.get_type_display()})"


class Transaction(models.Model):
    """
    Financial transaction (income or expense).
    Maps to Flutter's TransactionModel.
    """
    TRANSACTION_TYPES = [
        ('income', 'Revenu'),
        ('expense', 'Dépense'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='transactions')
    amount = models.DecimalField(max_digits=15, decimal_places=2, validators=[MinValueValidator(0)])
    type = models.CharField(max_length=10, choices=TRANSACTION_TYPES)
    category = models.ForeignKey(Category, on_delete=models.PROTECT, related_name='transactions')
    account = models.ForeignKey(
        Account, on_delete=models.SET_NULL, null=True, blank=True, related_name='transactions'
    )
    description = models.TextField(blank=True, null=True)
    date = models.DateField()
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'transactions'
        ordering = ['-date', '-created_at']

    def __str__(self):
        return f"{self.get_type_display()} {self.amount} - {self.category.name}"


class Budget(models.Model):
    """
    Monthly budget per category.
    Maps to Flutter's BudgetModel.
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='budgets')
    category = models.ForeignKey(Category, on_delete=models.CASCADE, related_name='budgets')
    amount = models.DecimalField(max_digits=15, decimal_places=2, validators=[MinValueValidator(0)])
    month = models.IntegerField()
    year = models.IntegerField()

    class Meta:
        db_table = 'budgets'
        unique_together = ['user', 'category', 'month', 'year']
        ordering = ['year', 'month']

    def __str__(self):
        return f"Budget {self.category.name} - {self.month}/{self.year}"

    @property
    def spent(self):
        """Calculate how much has been spent in this budget's category for the month."""
        from django.db.models import Sum
        total = Transaction.objects.filter(
            user=self.user,
            category=self.category,
            type='expense',
            date__month=self.month,
            date__year=self.year,
        ).aggregate(total=Sum('amount'))['total']
        return float(total or 0)

    @property
    def percentage(self):
        if self.amount > 0:
            return min(self.spent / float(self.amount), 1.0)
        return 0

    @property
    def remaining(self):
        return max(float(self.amount) - self.spent, 0)


class Goal(models.Model):
    """
    Savings goal.
    Maps to Flutter's GoalModel.
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='goals')
    title = models.CharField(max_length=200)
    target_amount = models.DecimalField(max_digits=15, decimal_places=2, validators=[MinValueValidator(0)])
    current_amount = models.DecimalField(max_digits=15, decimal_places=2, default=0)
    deadline = models.DateField(blank=True, null=True)
    image_key = models.CharField(max_length=100, blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'goals'
        ordering = ['-created_at']

    def __str__(self):
        return self.title

    @property
    def percentage(self):
        if self.target_amount > 0:
            return min(float(self.current_amount) / float(self.target_amount), 1.0)
        return 0

    @property
    def remaining(self):
        return max(float(self.target_amount) - float(self.current_amount), 0)

    @property
    def is_completed(self):
        return self.current_amount >= self.target_amount


class RecurringTransaction(models.Model):
    """
    Recurring transaction (daily, weekly, monthly, yearly).
    Maps to Flutter's RecurringTransactionModel.
    """
    PERIOD_CHOICES = [
        ('daily', 'Quotidien'),
        ('weekly', 'Hebdomadaire'),
        ('monthly', 'Mensuel'),
        ('yearly', 'Annuel'),
    ]
    TRANSACTION_TYPES = [
        ('income', 'Revenu'),
        ('expense', 'Dépense'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='recurring_transactions')
    amount = models.DecimalField(max_digits=15, decimal_places=2, validators=[MinValueValidator(0)])
    type = models.CharField(max_length=10, choices=TRANSACTION_TYPES)
    category = models.ForeignKey(Category, on_delete=models.PROTECT, related_name='recurring_transactions')
    account = models.ForeignKey(
        Account, on_delete=models.SET_NULL, null=True, blank=True, related_name='recurring_transactions'
    )
    description = models.TextField(blank=True, null=True)
    period = models.CharField(max_length=10, choices=PERIOD_CHOICES)
    start_date = models.DateField()
    next_date = models.DateField()
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'recurring_transactions'
        ordering = ['next_date']

    def __str__(self):
        return f"{self.get_type_display()} {self.amount} - {self.get_period_display()}"

    def calculate_next_date(self):
        """Calculate the next occurrence date based on the period."""
        from dateutil.relativedelta import relativedelta
        from datetime import timedelta

        if self.period == 'daily':
            return self.next_date + timedelta(days=1)
        elif self.period == 'weekly':
            return self.next_date + timedelta(weeks=1)
        elif self.period == 'monthly':
            return self.next_date + relativedelta(months=1)
        elif self.period == 'yearly':
            return self.next_date + relativedelta(years=1)
        return self.next_date


class MonthlyPlan(models.Model):
    """
    Monthly financial plan (needs vs expectations).
    Maps to Flutter's MonthlyPlan.
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='monthly_plans')
    month = models.IntegerField()
    year = models.IntegerField()
    needs = models.DecimalField(max_digits=15, decimal_places=2, default=0)
    expectations = models.DecimalField(max_digits=15, decimal_places=2, default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'monthly_plans'
        unique_together = ['user', 'month', 'year']
        ordering = ['-year', '-month']

    def __str__(self):
        return f"Plan {self.month}/{self.year}"


# ----------------------------------------------------------------------------
# PHASE 5: PROJECT PLANNING
# ----------------------------------------------------------------------------

class Project(models.Model):
    """
    A financial project with milestones and budget tracking.
    Users can plan projects, set budget targets, and track progress.
    """
    STATUS_CHOICES = [
        ('planning', 'Planification'),
        ('in_progress', 'En cours'),
        ('completed', 'Terminé'),
        ('paused', 'En pause'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='projects')
    title = models.CharField(max_length=200)
    description = models.TextField(blank=True, null=True)
    target_amount = models.DecimalField(max_digits=15, decimal_places=2, default=0, validators=[MinValueValidator(0)])
    current_amount = models.DecimalField(max_digits=15, decimal_places=2, default=0)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='planning')
    start_date = models.DateField()
    end_date = models.DateField(blank=True, null=True)
    color = models.CharField(max_length=20, default='0xFF2563EB')
    icon = models.CharField(max_length=50, default='rocket_launch')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'projects'
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.title} ({self.get_status_display()})"

    @property
    def percentage(self):
        if self.target_amount > 0:
            return min(float(self.current_amount) / float(self.target_amount), 1.0)
        return 0

    @property
    def remaining(self):
        return max(float(self.target_amount) - float(self.current_amount), 0)

    @property
    def is_completed(self):
        return self.status == 'completed' or self.current_amount >= self.target_amount

    @property
    def milestone_count(self):
        return self.milestones.count()

    @property
    def completed_milestones(self):
        return self.milestones.filter(status='completed').count()


class ProjectMilestone(models.Model):
    """
    A step/milestone within a project, with its own budget target.
    """
    STATUS_CHOICES = [
        ('pending', 'En attente'),
        ('in_progress', 'En cours'),
        ('completed', 'Terminé'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    project = models.ForeignKey(Project, on_delete=models.CASCADE, related_name='milestones')
    title = models.CharField(max_length=200)
    description = models.TextField(blank=True, null=True)
    target_amount = models.DecimalField(max_digits=15, decimal_places=2, default=0, validators=[MinValueValidator(0)])
    current_amount = models.DecimalField(max_digits=15, decimal_places=2, default=0)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    due_date = models.DateField(blank=True, null=True)
    order = models.IntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'project_milestones'
        ordering = ['order', 'created_at']

    def __str__(self):
        return f"{self.title} ({self.get_status_display()})"

    @property
    def percentage(self):
        if self.target_amount > 0:
            return min(float(self.current_amount) / float(self.target_amount), 1.0)
        return 0

    @property
    def is_completed(self):
        return self.status == 'completed'


# ----------------------------------------------------------------------------
# PHASE 6: GAMIFICATION
# ----------------------------------------------------------------------------

class Challenge(models.Model):
    """
    A gamification challenge (e.g. Save $50 on food, No Spend Weekend).
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    title = models.CharField(max_length=200)
    description = models.TextField()
    points = models.IntegerField(default=10)
    icon = models.CharField(max_length=50, default='emoji_events')
    color = models.CharField(max_length=20, default='0xFFFFD700')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'challenges'
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.title} ({self.points} pts)"


class UserBadge(models.Model):
    """
    A badge earned by a user for completing a challenge.
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='badges')
    challenge = models.ForeignKey(Challenge, on_delete=models.CASCADE, related_name='earned_by')
    earned_date = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'user_badges'
        unique_together = ['user', 'challenge']
        ordering = ['-earned_date']

    def __str__(self):
        return f"{self.user.first_name} earned {self.challenge.title}"
