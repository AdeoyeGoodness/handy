from datetime import datetime
from typing import Optional

from sqlmodel import Field, Relationship, SQLModel


class MessageThread(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    initiator_id: int = Field(foreign_key="user.id")
    receiver_id: int = Field(foreign_key="user.id")
    booking_id: Optional[int] = Field(default=None, foreign_key="bookingrequest.id")
    last_message_at: datetime = Field(default_factory=datetime.utcnow)

    messages: list["Message"] = Relationship(back_populates="thread")


class MessageThreadCreate(SQLModel):
    receiver_id: int
    booking_id: Optional[int] = None


class Message(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    thread_id: int = Field(foreign_key="messagethread.id")
    sender_id: int = Field(foreign_key="user.id")
    content: str
    message_type: str = Field(default="TEXT")
    read_at: Optional[datetime] = None
    sent_at: datetime = Field(default_factory=datetime.utcnow)

    thread: Optional[MessageThread] = Relationship(back_populates="messages")


class MessageCreate(SQLModel):
    content: str

