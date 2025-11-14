from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import Session, select

from ...models.message import Message, MessageCreate, MessageThread, MessageThreadCreate
from ...models.user import User
from ..deps import get_current_active_user, get_db

router = APIRouter(prefix="/messages", tags=["messages"])


@router.post("/threads", response_model=MessageThread, status_code=status.HTTP_201_CREATED)
def create_thread(
    payload: MessageThreadCreate,
    current_user: User = Depends(get_current_active_user),
    session: Session = Depends(get_db),
) -> MessageThread:
    existing = session.exec(
        select(MessageThread)
        .where(MessageThread.initiator_id == current_user.id)
        .where(MessageThread.receiver_id == payload.receiver_id)
    ).first()
    if existing:
        return existing

    thread = MessageThread(
        initiator_id=current_user.id,
        receiver_id=payload.receiver_id,
        booking_id=payload.booking_id,
    )
    session.add(thread)
    session.commit()
    session.refresh(thread)
    return thread


@router.get("/threads", response_model=list[MessageThread])
def list_threads(current_user: User = Depends(get_current_active_user), session: Session = Depends(get_db)):
    threads = session.exec(
        select(MessageThread).where(
            (MessageThread.initiator_id == current_user.id) | (MessageThread.receiver_id == current_user.id)
        )
    ).all()
    return threads


@router.post("/threads/{thread_id}/messages", response_model=Message, status_code=status.HTTP_201_CREATED)
def post_message(
    thread_id: int,
    payload: MessageCreate,
    current_user: User = Depends(get_current_active_user),
    session: Session = Depends(get_db),
) -> Message:
    thread = session.get(MessageThread, thread_id)
    if not thread:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Thread not found")

    if current_user.id not in {thread.initiator_id, thread.receiver_id}:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not allowed")

    message = Message(thread_id=thread_id, sender_id=current_user.id, content=payload.content)
    thread.last_message_at = datetime.utcnow()
    session.add(message)
    session.add(thread)
    session.commit()
    session.refresh(message)
    return message


@router.get("/threads/{thread_id}/messages", response_model=list[Message])
def get_messages(
    thread_id: int,
    current_user: User = Depends(get_current_active_user),
    session: Session = Depends(get_db),
) -> list[Message]:
    thread = session.get(MessageThread, thread_id)
    if not thread:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Thread not found")
    if current_user.id not in {thread.initiator_id, thread.receiver_id}:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not allowed")

    messages = session.exec(select(Message).where(Message.thread_id == thread_id)).all()
    return messages

