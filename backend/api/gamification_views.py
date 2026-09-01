from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from .models import Challenge, UserBadge

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def list_challenges(request):
    """
    GET /api/gamification/challenges/
    Returns all challenges and indicates which ones the user has completed.
    """
    user = request.user
    challenges = Challenge.objects.all()
    earned_badges = UserBadge.objects.filter(user=user).values_list('challenge_id', flat=True)

    result = []
    for c in challenges:
        result.append({
            'id': str(c.id),
            'title': c.title,
            'description': c.description,
            'points': c.points,
            'icon': c.icon,
            'color': c.color,
            'is_completed': c.id in earned_badges
        })

    return Response(result)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def list_badges(request):
    """
    GET /api/gamification/badges/
    Returns all badges earned by the user.
    """
    user = request.user
    badges = UserBadge.objects.filter(user=user).select_related('challenge')
    
    result = []
    for b in badges:
        result.append({
            'badge_id': str(b.id),
            'earned_date': b.earned_date.isoformat(),
            'challenge': {
                'id': str(b.challenge.id),
                'title': b.challenge.title,
                'points': b.challenge.points,
                'icon': b.challenge.icon,
                'color': b.challenge.color,
            }
        })
        
    return Response(result)
