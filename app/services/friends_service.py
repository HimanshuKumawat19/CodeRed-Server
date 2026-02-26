# from sqlalchemy.ext.asyncio import AsyncSession
# from sqlalchemy import select
# from typing import Optional

# from app.models.friend import Friend
# from app.schemas.friends import FriendCreate

# class FriendService:

#     @staticmethod
#     async def create_friend_connection(
#         db: AsyncSession,
#         friend_data:  FriendCreate
#     ):
#         new_friend_conn = Friend(
#             user_id = friend_data
#         )