"""
Budgeto AI Views.

Endpoints for the AI Chatbot and Smart Receipt Scanning (OCR).
"""
import os
import json
import base64
from datetime import date
from django.conf import settings
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from openai import OpenAI

from .models import Transaction, Category, Account

# Initialize OpenAI client
client = OpenAI(api_key=os.environ.get("OPENAI_API_KEY", ""))


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def ai_chat(request):
    """
    POST /api/ai/chat/
    Analyzes user text to extract a financial intent (e.g. adding a transaction)
    using OpenAI, and executes it if it's an actionable intent.
    """
    user_text = request.data.get('message', '')
    if not user_text:
        return Response({'error': 'Message cannot be empty.'}, status=status.HTTP_400_BAD_REQUEST)

    # Prepare categories list for the prompt
    categories = list(Category.objects.values('id', 'name', 'type'))
    cat_str = "\n".join([f"- {c['id']} ({c['name']}, {c['type']})" for c in categories])

    system_prompt = f"""
    You are an intelligent financial assistant for a budget app called Budgeto.
    Today's date is {date.today().isoformat()}.

    The user will send you a message. You must analyze the message and return a JSON object representing the user's intent.

    Possible intents:
    1. "add_transaction": If the user describes spending money or receiving money.
    2. "query": If the user asks a question about their budget, savings, or general advice.

    If intent is "add_transaction", you MUST provide:
    - "amount": (float) the amount spent or received.
    - "type": "expense" or "income".
    - "category_id": Pick the MOST RELEVANT category ID from this list:
    {cat_str}
    - "description": (string) a short description (e.g. the merchant name or item).
    - "date": (string) YYYY-MM-DD. Usually today unless specified otherwise.

    If intent is "query", you MUST provide:
    - "answer": (string) a helpful, concise answer to their question. (You won't have access to their real DB yet, so give general advice or ask them to check the app dashboard).

    Output strictly valid JSON and nothing else. Example:
    {{
      "intent": "add_transaction",
      "data": {{
        "amount": 15.50,
        "type": "expense",
        "category_id": "cat_food",
        "description": "Starbucks",
        "date": "2024-03-10"
      }}
    }}
    """

    try:
        completion = client.chat.completions.create(
            model="gpt-4o",  # or gpt-3.5-turbo
            response_format={ "type": "json_object" },
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_text}
            ]
        )
        
        response_json = json.loads(completion.choices[0].message.content)
        intent = response_json.get('intent')
        data = response_json.get('data', {})

        if intent == 'add_transaction':
            # Optionally, we can save it directly or just return it to the frontend for confirmation.
            # Let's return it so the frontend can show a beautiful confirmation UI.
            return Response({
                'action': 'confirm_transaction',
                'transaction_data': data,
                'message': f"J'ai préparé une transaction de {data.get('amount')}€ pour {data.get('description')}. Souhaitez-vous la valider ?"
            })
        elif intent == 'query':
            return Response({
                'action': 'chat_response',
                'message': data.get('answer', "Désolé, je n'ai pas pu analyser votre demande.")
            })
        else:
            return Response({'action': 'chat_response', 'message': "Je ne suis pas sûr de comprendre."})

    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def scan_receipt(request):
    """
    POST /api/ai/scan-receipt/
    Accepts an image file, sends it to OpenAI Vision, and extracts transaction details.
    """
    if 'image' not in request.FILES:
        return Response({'error': 'No image provided.'}, status=status.HTTP_400_BAD_REQUEST)

    image_file = request.FILES['image']
    base64_image = base64.b64encode(image_file.read()).decode('utf-8')

    categories = list(Category.objects.values('id', 'name', 'type'))
    cat_str = "\n".join([f"- {c['id']} ({c['name']}, {c['type']})" for c in categories])

    system_prompt = f"""
    You are an AI assistant that extracts data from receipts.
    Extract the following from the provided image:
    1. Total amount (float).
    2. Date (YYYY-MM-DD format). If not found, use today's date ({date.today().isoformat()}).
    3. Merchant name (string).
    4. Category ID: Pick the best match from this list:
    {cat_str}

    Output strictly valid JSON:
    {{
      "amount": 12.99,
      "date": "2024-03-10",
      "merchant": "McDonalds",
      "category_id": "cat_food"
    }}
    """

    try:
        completion = client.chat.completions.create(
            model="gpt-4o",
            response_format={ "type": "json_object" },
            messages=[
                {
                    "role": "user",
                    "content": [
                        {"type": "text", "text": system_prompt},
                        {
                            "type": "image_url",
                            "image_url": {
                                "url": f"data:image/jpeg;base64,{base64_image}"
                            }
                        }
                    ]
                }
            ]
        )
        
        response_json = json.loads(completion.choices[0].message.content)
        return Response(response_json)

    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
