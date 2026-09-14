from pydantic import BaseModel


class ProfileCreate(BaseModel):
    user_id: int
    caretaker_id: int


class ProfileResponse(ProfileCreate):
    profile_id: int

    class Config:
        from_attributes = True