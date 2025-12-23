from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.authtoken.models import Token
from django.contrib.auth import logout
from .serializers import UserRegistrationSerializer, UserLoginSerializer, UserSerializer
from .models import User

@api_view(['POST'])
@permission_classes([AllowAny])
def register(request):
    # Accept common alternate field names from various clients
    incoming = request.data.copy()
    # Temporary debug logging to diagnose client payload shape
    try:
        print('[AUTH][register] Raw request.data:', dict(request.data))
    except Exception:
        print('[AUTH][register] Raw request.data present but could not be printed')

    # Normalize possible variants for password confirmation
    if 'password_confirm' not in incoming or not incoming.get('password_confirm'):
        for alt_key in ('confirm_password', 'password2', 'passwordConfirm', 'password_confirmation'):
            if alt_key in incoming and incoming.get(alt_key):
                incoming['password_confirm'] = incoming.get(alt_key)
                break
    # Final fallback: if still missing, mirror password (compatibility for clients that only send one field)
    if (not incoming.get('password_confirm')) and incoming.get('password'):
        incoming['password_confirm'] = incoming.get('password')

    # Default user_type if not provided
    if 'user_type' not in incoming:
        incoming['user_type'] = 'student'

    serializer = UserRegistrationSerializer(data=incoming)
    if serializer.is_valid():
        user = serializer.save()
        token, created = Token.objects.get_or_create(user=user)
        return Response({
            'user': UserSerializer(user).data,
            'token': token.key,
            'message': 'User registered successfully'
        }, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['POST'])
@permission_classes([AllowAny])
def login(request):
    serializer = UserLoginSerializer(data=request.data)
    if serializer.is_valid():
        user = serializer.validated_data['user']
        token, created = Token.objects.get_or_create(user=user)
        return Response({
            'user': UserSerializer(user).data,
            'token': token.key,
            'user_type': user.user_type,
            'user_id': user.id,
            'message': 'Login successful'
        }, status=status.HTTP_200_OK)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def logout_view(request):
    try:
        request.user.auth_token.delete()
        logout(request)
        return Response({'message': 'Logout successful'}, status=status.HTTP_200_OK)
    except:
        return Response({'error': 'Something went wrong'}, status=status.HTTP_400_BAD_REQUEST)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def profile(request):
    user = request.user
    serializer = UserSerializer(user)
    return Response(serializer.data, status=status.HTTP_200_OK)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def users_list(request):
    if request.user.user_type != 'admin':
        return Response({'error': 'Permission denied'}, status=status.HTTP_403_FORBIDDEN)

    users = User.objects.all()
    serializer = UserSerializer(users, many=True)
    return Response(serializer.data, status=status.HTTP_200_OK)