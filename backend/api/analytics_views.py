"""
Advanced Analytics Views (Phase 5).
Includes predictive budgeting (forecast) and hidden subscription detection.
"""
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django.db.models import Sum
from datetime import date, timedelta
import calendar

from .models import Transaction

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def budget_forecast(request):
    """
    GET /api/analytics/forecast/
    Predicts the end-of-month spending based on the current month's spending rate.
    """
    user = request.user
    today = date.today()
    month = int(request.query_params.get('month', today.month))
    year = int(request.query_params.get('year', today.year))

    # Find total days in the target month
    _, last_day = calendar.monthrange(year, month)
    
    # Calculate days passed in that month
    if year == today.year and month == today.month:
        days_passed = today.day
    elif year < today.year or (year == today.year and month < today.month):
        days_passed = last_day
    else:
        days_passed = 0

    # Get total spent in this month so far
    expenses = Transaction.objects.filter(
        user=user,
        type='expense',
        date__year=year,
        date__month=month
    ).aggregate(total=Sum('amount'))['total'] or 0

    if days_passed == 0:
        daily_average = 0
        projected_total = 0
    else:
        daily_average = expenses / days_passed
        projected_total = daily_average * last_day

    return Response({
        'current_spent': float(expenses),
        'daily_average': float(daily_average),
        'projected_end_of_month': float(projected_total),
        'days_passed': days_passed,
        'total_days': last_day
    })


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def detect_subscriptions(request):
    """
    GET /api/analytics/subscriptions/
    Detects potential hidden subscriptions by finding identical amounts 
    from the same merchant/description occurring repeatedly.
    """
    user = request.user
    
    # Get expenses from the last 90 days to find patterns
    three_months_ago = date.today() - timedelta(days=90)
    
    transactions = Transaction.objects.filter(
        user=user,
        type='expense',
        date__gte=three_months_ago
    ).order_by('description', 'amount', 'date')

    # A simple algorithm to detect recurrence:
    # Group by (description, amount). If count >= 2, it might be a subscription.
    suspected_subs = {}
    
    for t in transactions:
        # Ignore empty descriptions
        if not t.description:
            continue
            
        key = f"{t.description.lower().strip()}_{t.amount}"
        if key not in suspected_subs:
            suspected_subs[key] = {
                'description': t.description,
                'amount': float(t.amount),
                'category_id': t.category.id if t.category else None,
                'dates': [],
                'count': 0
            }
        
        suspected_subs[key]['dates'].append(t.date.isoformat())
        suspected_subs[key]['count'] += 1

    # Filter only those that occur 2 or more times
    subscriptions = [sub for key, sub in suspected_subs.items() if sub['count'] >= 2]

    return Response({
        'detected_subscriptions': subscriptions,
        'total_monthly_estimated': sum(sub['amount'] for sub in subscriptions)
    })
