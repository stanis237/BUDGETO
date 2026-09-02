"""
Budgeto API Views.

ViewSets and custom views for all API endpoints.
"""
import csv
import io
from datetime import date

from django.contrib.auth import get_user_model
from django.db.models import Sum, Q
from django.http import HttpResponse
from rest_framework import viewsets, status, generics, permissions
from rest_framework.decorators import action, api_view, permission_classes
from rest_framework.response import Response
from rest_framework_simplejwt.tokens import RefreshToken

from .models import Account, Category, Transaction, Budget, Goal, RecurringTransaction, MonthlyPlan, Project, ProjectMilestone
from .serializers import (
    RegisterSerializer, LoginSerializer, UserSerializer,
    AccountSerializer, CategorySerializer,
    TransactionReadSerializer, TransactionWriteSerializer,
    BudgetReadSerializer, BudgetWriteSerializer,
    GoalSerializer, GoalContributionSerializer,
    RecurringTransactionReadSerializer, RecurringTransactionWriteSerializer,
    MonthlyPlanSerializer,
    MonthlySummarySerializer, CategoryExpenseSerializer,
    DailyTotalSerializer, WeeklyTotalSerializer, BudgetSummarySerializer,
    HouseholdSerializer,
    ProjectReadSerializer, ProjectWriteSerializer,
    ProjectContributionSerializer, ProjectMilestoneSerializer,
)

User = get_user_model()


# ──────────────────────────────────────────────
# Auth Views
# ──────────────────────────────────────────────

class RegisterView(generics.CreateAPIView):
    """User registration endpoint."""
    serializer_class = RegisterSerializer
    permission_classes = [permissions.AllowAny]

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()

        # Create default cash account for the user so they can immediately transact
        Account.objects.get_or_create(
            user=user,
            name='Espèces',
            defaults={
                'type': 'cash',
                'balance': 0,
                'icon': 'account_balance_wallet',
                'color': '0xFF2563EB',
            }
        )

        # Generate JWT tokens
        refresh = RefreshToken.for_user(user)

        return Response({
            'user': UserSerializer(user).data,
            'tokens': {
                'refresh': str(refresh),
                'access': str(refresh.access_token),
            }
        }, status=status.HTTP_201_CREATED)


class LoginView(generics.GenericAPIView):
    """User login endpoint."""
    serializer_class = LoginSerializer
    permission_classes = [permissions.AllowAny]

    def post(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        email = serializer.validated_data['email']
        password = serializer.validated_data['password']

        try:
            user = User.objects.get(email=email)
        except User.DoesNotExist:
            return Response(
                {'error': 'Email ou mot de passe incorrect.'},
                status=status.HTTP_401_UNAUTHORIZED
            )

        if not user.check_password(password):
            return Response(
                {'error': 'Email ou mot de passe incorrect.'},
                status=status.HTTP_401_UNAUTHORIZED
            )

        refresh = RefreshToken.for_user(user)

        return Response({
            'user': UserSerializer(user).data,
            'tokens': {
                'refresh': str(refresh),
                'access': str(refresh.access_token),
            }
        })


class MeView(generics.RetrieveUpdateAPIView):
    """Get or update current user profile."""
    serializer_class = UserSerializer

    def get_object(self):
        return self.request.user


# ──────────────────────────────────────────────
# Account ViewSet
# ──────────────────────────────────────────────

class AccountViewSet(viewsets.ModelViewSet):
    """CRUD for financial accounts."""
    serializer_class = AccountSerializer

    def get_queryset(self):
        user = self.request.user
        if user.household:
            return Account.objects.filter(user__household=user.household)
        return Account.objects.filter(user=self.request.user)


# ──────────────────────────────────────────────
# Category ViewSet
# ──────────────────────────────────────────────

class CategoryViewSet(viewsets.ReadOnlyModelViewSet):
    """Read-only access to categories (seeded data)."""
    serializer_class = CategorySerializer
    queryset = Category.objects.all()
    permission_classes = [permissions.AllowAny]

    def get_queryset(self):
        qs = Category.objects.all()
        cat_type = self.request.query_params.get('type')
        if cat_type:
            qs = qs.filter(type=cat_type)
        return qs


# ──────────────────────────────────────────────
# Transaction ViewSet
# ──────────────────────────────────────────────

class TransactionViewSet(viewsets.ModelViewSet):
    """CRUD for transactions + analytics endpoints."""

    def get_serializer_class(self):
        if self.action in ['create', 'update', 'partial_update']:
            return TransactionWriteSerializer
        return TransactionReadSerializer

    def get_queryset(self):
        user = self.request.user
        if user.household:
            qs = Transaction.objects.filter(user__household=user.household)
        else:
            qs = Transaction.objects.filter(user=user)
        qs = qs.select_related('category', 'account')
        
        # Optional month/year filtering
        month = self.request.query_params.get('month')
        year = self.request.query_params.get('year')
        if month and year:
            qs = qs.filter(date__month=int(month), date__year=int(year))
        return qs

    @action(detail=False, methods=['get'])
    def summary(self, request):
        """GET /api/transactions/summary/?month=X&year=Y — Monthly income/expense summary."""
        month = int(request.query_params.get('month', date.today().month))
        year = int(request.query_params.get('year', date.today().year))

        user = request.user
        base_filter = Q(user__household=user.household) if user.household else Q(user=user)

        results = Transaction.objects.filter(
            base_filter,
            date__month=month,
            date__year=year,
        ).values('type').annotate(total=Sum('amount'))

        income = 0
        expense = 0
        for r in results:
            if r['type'] == 'income':
                income = float(r['total'])
            elif r['type'] == 'expense':
                expense = float(r['total'])

        data = {'income': income, 'expense': expense, 'balance': income - expense}
        return Response(MonthlySummarySerializer(data).data)

    @action(detail=False, methods=['get'], url_path='by-category')
    def by_category(self, request):
        """GET /api/transactions/by-category/?month=X&year=Y — Expenses by category."""
        month = int(request.query_params.get('month', date.today().month))
        year = int(request.query_params.get('year', date.today().year))

        user = request.user
        base_filter = Q(user__household=user.household) if user.household else Q(user=user)

        results = Transaction.objects.filter(
            base_filter,
            type='expense',
            date__month=month,
            date__year=year,
        ).values(
            'category__id', 'category__name', 'category__icon', 'category__color'
        ).annotate(total=Sum('amount')).order_by('-total')

        data = [
            {
                'id': r['category__id'],
                'name': r['category__name'],
                'icon': r['category__icon'],
                'color': r['category__color'],
                'total': float(r['total']),
            }
            for r in results
        ]
        return Response(CategoryExpenseSerializer(data, many=True).data)

    @action(detail=False, methods=['get'], url_path='daily-totals')
    def daily_totals(self, request):
        """GET /api/transactions/daily-totals/?type=X&month=Y&year=Z"""
        tx_type = request.query_params.get('type', 'expense')
        month = int(request.query_params.get('month', date.today().month))
        year = int(request.query_params.get('year', date.today().year))

        user = request.user
        base_filter = Q(user__household=user.household) if user.household else Q(user=user)

        results = Transaction.objects.filter(
            base_filter,
            type=tx_type,
            date__month=month,
            date__year=year,
        ).values('date__day').annotate(total=Sum('amount')).order_by('date__day')

        data = [
            {'day': str(r['date__day']).zfill(2), 'total': float(r['total'])}
            for r in results
        ]
        return Response(DailyTotalSerializer(data, many=True).data)

    @action(detail=False, methods=['get'], url_path='weekly-totals')
    def weekly_totals(self, request):
        """GET /api/transactions/weekly-totals/?type=X&month=Y&year=Z"""
        from django.db.models.functions import ExtractWeek
        tx_type = request.query_params.get('type', 'expense')
        month = int(request.query_params.get('month', date.today().month))
        year = int(request.query_params.get('year', date.today().year))

        user = request.user
        base_filter = Q(user__household=user.household) if user.household else Q(user=user)

        results = Transaction.objects.filter(
            base_filter,
            type=tx_type,
            date__month=month,
            date__year=year,
        ).annotate(week=ExtractWeek('date')).values('week').annotate(
            total=Sum('amount')
        ).order_by('week')

        data = [
            {'week': str(r['week']), 'total': float(r['total'])}
            for r in results
        ]
        return Response(WeeklyTotalSerializer(data, many=True).data)


# ──────────────────────────────────────────────
# Budget ViewSet
# ──────────────────────────────────────────────

class BudgetViewSet(viewsets.ModelViewSet):
    """CRUD for budgets + summary endpoint."""

    def get_serializer_class(self):
        if self.action in ['create', 'update', 'partial_update']:
            return BudgetWriteSerializer
        return BudgetReadSerializer

    def get_queryset(self):
        user = self.request.user
        if user.household:
            qs = Budget.objects.filter(user__household=user.household)
        else:
            qs = Budget.objects.filter(user=user)
        qs = qs.select_related('category')
        month = self.request.query_params.get('month')
        year = self.request.query_params.get('year')
        if month and year:
            qs = qs.filter(month=int(month), year=int(year))
        return qs

    @action(detail=False, methods=['get'])
    def summary(self, request):
        """GET /api/budgets/summary/?month=X&year=Y"""
        month = int(request.query_params.get('month', date.today().month))
        year = int(request.query_params.get('year', date.today().year))

        user = request.user
        base_filter = Q(user__household=user.household) if user.household else Q(user=user)

        budgets = Budget.objects.filter(
            base_filter, month=month, year=year
        ).select_related('category')

        total_budget = sum(float(b.amount) for b in budgets)
        total_spent = sum(b.spent for b in budgets)

        data = {
            'total': total_budget,
            'spent': total_spent,
            'remaining': total_budget - total_spent,
        }
        return Response(BudgetSummarySerializer(data).data)


# ──────────────────────────────────────────────
# Goal ViewSet
# ──────────────────────────────────────────────

class GoalViewSet(viewsets.ModelViewSet):
    """CRUD for savings goals + contribution endpoint."""
    serializer_class = GoalSerializer

    def get_queryset(self):
        user = self.request.user
        if user.household:
            return Goal.objects.filter(user__household=user.household)
        return Goal.objects.filter(user=user)

    @action(detail=True, methods=['post'])
    def contribute(self, request, pk=None):
        """POST /api/goals/{id}/contribute/ — Add a contribution."""
        goal = self.get_object()
        serializer = GoalContributionSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        amount = serializer.validated_data['amount']
        new_amount = min(
            float(goal.current_amount) + float(amount),
            float(goal.target_amount)
        )
        goal.current_amount = new_amount
        goal.save()

        return Response(GoalSerializer(goal).data)


# ──────────────────────────────────────────────
# Recurring Transaction ViewSet
# ──────────────────────────────────────────────

class RecurringTransactionViewSet(viewsets.ModelViewSet):
    """CRUD for recurring transactions + processing endpoint."""

    def get_serializer_class(self):
        if self.action in ['create', 'update', 'partial_update']:
            return RecurringTransactionWriteSerializer
        return RecurringTransactionReadSerializer

    def get_queryset(self):
        user = self.request.user
        if user.household:
            return RecurringTransaction.objects.filter(
                user__household=user.household
            ).select_related('category', 'account')
        return RecurringTransaction.objects.filter(
            user=user
        ).select_related('category', 'account')

    @action(detail=False, methods=['post'])
    def process(self, request):
        """
        POST /api/recurring-transactions/process/
        Process all due recurring transactions, creating actual transactions.
        """
        today = date.today()
        due = RecurringTransaction.objects.filter(
            user=request.user,
            next_date__lte=today,
        )

        created_transactions = []
        for rt in due:
            # Create the actual transaction
            tx = Transaction.objects.create(
                user=request.user,
                amount=rt.amount,
                type=rt.type,
                category=rt.category,
                account=rt.account,
                description=rt.description,
                date=rt.next_date,
            )
            created_transactions.append(tx)

            # Update next_date
            rt.next_date = rt.calculate_next_date()
            rt.save()

        return Response({
            'processed': len(created_transactions),
            'transactions': TransactionReadSerializer(created_transactions, many=True).data,
        })


# ──────────────────────────────────────────────
# Monthly Plan ViewSet
# ──────────────────────────────────────────────

class MonthlyPlanViewSet(viewsets.ModelViewSet):
    """CRUD for monthly plans (upsert on create)."""
    serializer_class = MonthlyPlanSerializer

    def get_queryset(self):
        user = self.request.user
        if user.household:
            qs = MonthlyPlan.objects.filter(user__household=user.household)
        else:
            qs = MonthlyPlan.objects.filter(user=user)
        month = self.request.query_params.get('month')
        year = self.request.query_params.get('year')
        if month and year:
            qs = qs.filter(month=int(month), year=int(year))
        return qs


# ──────────────────────────────────────────────
# Household ViewSet
# ──────────────────────────────────────────────

class HouseholdViewSet(viewsets.ModelViewSet):
    """ViewSet to create, join or leave a Shared Budget Household."""
    serializer_class = HouseholdSerializer

    def get_queryset(self):
        user = self.request.user
        if user.household:
            return Household.objects.filter(id=user.household.id)
        return Household.objects.none()

    def perform_create(self, serializer):
        household = serializer.save()
        user = self.request.user
        user.household = household
        user.save()

    @action(detail=False, methods=['post'])
    def join(self, request):
        """POST /api/households/join/ — Join a household using its UUID."""
        household_id = request.data.get('household_id')
        if not household_id:
            return Response({'error': 'household_id required'}, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            household = Household.objects.get(id=household_id)
        except Household.DoesNotExist:
            return Response({'error': 'Household not found'}, status=status.HTTP_404_NOT_FOUND)

        user = request.user
        user.household = household
        user.save()
        return Response(HouseholdSerializer(household).data)

    @action(detail=False, methods=['post'])
    def leave(self, request):
        """POST /api/households/leave/ — Leave current household."""
        user = request.user
        user.household = None
        user.save()
        return Response({'message': 'Successfully left the household'})


# ──────────────────────────────────────────────
# Export Views
# ──────────────────────────────────────────────

@api_view(['GET'])
def export_csv(request):
    """
    GET /api/export/csv/?month=X&year=Y
    Export transactions as CSV file.
    """
    month = request.query_params.get('month')
    year = request.query_params.get('year')

    qs = Transaction.objects.filter(user=request.user).select_related('category')
    if month and year:
        qs = qs.filter(date__month=int(month), date__year=int(year))

    response = HttpResponse(content_type='text/csv')
    response['Content-Disposition'] = f'attachment; filename="transactions_stankap.csv"'
    response.write('\ufeff')  # BOM for Excel compatibility

    writer = csv.writer(response, delimiter=';')
    writer.writerow(['Date', 'Type', 'Catégorie', 'Description', 'Montant'])

    for tx in qs.order_by('-date'):
        writer.writerow([
            tx.date.strftime('%d/%m/%Y'),
            'Revenu' if tx.type == 'income' else 'Dépense',
            tx.category.name if tx.category else 'Autre',
            tx.description or '',
            f"{tx.amount:.2f}",
        ])

    return response


@api_view(['GET'])
def export_pdf(request):
    """
    GET /api/export/pdf/?month=X&year=Y
    Export transactions as PDF file.
    """
    from reportlab.lib.pagesizes import A4
    from reportlab.lib import colors
    from reportlab.lib.units import cm
    from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer, Image as RLImage
    from reportlab.lib.styles import getSampleStyleSheet
    import os

    month = request.query_params.get('month')
    year = request.query_params.get('year')

    qs = Transaction.objects.filter(user=request.user).select_related('category')
    if month and year:
        qs = qs.filter(date__month=int(month), date__year=int(year))

    buffer = io.BytesIO()
    doc = SimpleDocTemplate(buffer, pagesize=A4)
    styles = getSampleStyleSheet()
    elements = []

    # Logo
    logo_path = os.path.join(settings.BASE_DIR, '..', 'assets', 'images', 'app_icon.png')
    if os.path.exists(logo_path):
        elements.append(RLImage(logo_path, width=48, height=48))
        elements.append(Spacer(1, 0.5 * cm))

    # Title
    title_text = 'Rapport de Transactions - Stankap'
    if month and year:
        title_text += f' ({month}/{year})'
    elements.append(Paragraph(title_text, styles['Title']))
    elements.append(Spacer(1, 1 * cm))

    # Table data
    data = [['Date', 'Type', 'Catégorie', 'Description', 'Montant']]
    for tx in qs.order_by('-date'):
        data.append([
            tx.date.strftime('%d/%m/%Y'),
            'Revenu' if tx.type == 'income' else 'Dépense',
            tx.category.name if tx.category else 'Autre',
            (tx.description or '')[:40],
            f"{tx.amount:.2f}",
        ])

    if len(data) > 1:
        table = Table(data, colWidths=[3 * cm, 2.5 * cm, 3 * cm, 5 * cm, 3 * cm])
        table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#2563EB')),
            ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
            ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, 0), 10),
            ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
            ('BACKGROUND', (0, 1), (-1, -1), colors.HexColor('#f8fafc')),
            ('GRID', (0, 0), (-1, -1), 0.5, colors.grey),
            ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, colors.HexColor('#f1f5f9')]),
        ]))
        elements.append(table)
    else:
        elements.append(Paragraph('Aucune transaction trouvée.', styles['Normal']))

    doc.build(elements)
    buffer.seek(0)

    response = HttpResponse(buffer, content_type='application/pdf')
    response['Content-Disposition'] = 'attachment; filename="transactions_stankap.pdf"'
    return response


# ──────────────────────────────────────────────
# Project ViewSet
# ──────────────────────────────────────────────

class ProjectViewSet(viewsets.ModelViewSet):
    """CRUD for financial projects + contribution endpoint."""

    def get_serializer_class(self):
        if self.action in ['create', 'update', 'partial_update']:
            return ProjectWriteSerializer
        return ProjectReadSerializer

    def get_queryset(self):
        user = self.request.user
        if user.household:
            return Project.objects.filter(user__household=user.household).prefetch_related('milestones')
        return Project.objects.filter(user=user).prefetch_related('milestones')

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        project = serializer.save()
        return Response(ProjectReadSerializer(project).data, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=['post'])
    def contribute(self, request, pk=None):
        """POST /api/projects/{id}/contribute/ — Add funds to a project."""
        project = self.get_object()
        serializer = ProjectContributionSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        amount = float(serializer.validated_data['amount'])
        new_amount = min(
            float(project.current_amount) + amount,
            float(project.target_amount)
        )
        project.current_amount = new_amount

        # Auto-complete if target reached
        if new_amount >= float(project.target_amount):
            project.status = 'completed'

        project.save()
        return Response(ProjectReadSerializer(project).data)

    @action(detail=True, methods=['post'], url_path='update-status')
    def update_status(self, request, pk=None):
        """POST /api/projects/{id}/update-status/ — Change project status."""
        project = self.get_object()
        new_status = request.data.get('status')
        if new_status not in dict(Project.STATUS_CHOICES):
            return Response(
                {'error': 'Statut invalide'},
                status=status.HTTP_400_BAD_REQUEST
            )
        project.status = new_status
        project.save()
        return Response(ProjectReadSerializer(project).data)


class ProjectMilestoneViewSet(viewsets.ModelViewSet):
    """CRUD for project milestones."""
    serializer_class = ProjectMilestoneSerializer

    def get_queryset(self):
        user = self.request.user
        if user.household:
            return ProjectMilestone.objects.filter(
                project__user__household=user.household
            )
        return ProjectMilestone.objects.filter(project__user=user)

    @action(detail=True, methods=['post'], url_path='update-status')
    def update_status(self, request, pk=None):
        """POST /api/project-milestones/{id}/update-status/ — Change milestone status."""
        milestone = self.get_object()
        new_status = request.data.get('status')
        if new_status not in dict(ProjectMilestone.STATUS_CHOICES):
            return Response(
                {'error': 'Statut invalide'},
                status=status.HTTP_400_BAD_REQUEST
            )
        milestone.status = new_status
        milestone.save()
        return Response(ProjectMilestoneSerializer(milestone).data)

