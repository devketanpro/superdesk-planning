from typing import Union, List, Dict, Any, TypedDict, Optional
from bson.objectid import ObjectId
from bson.errors import InvalidId
from datetime import datetime
from flask_babel import lazy_gettext
from eve.utils import str_to_date
from superdesk.utc import utc_to_local
import arrow
from flask import current_app as app
import pytz


class FormattedContact(TypedDict):
    name: str
    organisation: str
    email: List[str]
    phone: List[str]
    mobile: List[str]
    website: str


MULTI_DAY_SECONDS = 24 * 60 * 60  # Number of seconds for an multi-day event
ALL_DAY_SECONDS = MULTI_DAY_SECONDS - 1  # Number of seconds for an all-day event


def try_cast_object_id(value: str) -> Union[ObjectId, str]:
    try:
        return ObjectId(value)
    except InvalidId:
        return value


def get_formatted_contacts(event: Dict[str, Any]) -> List[FormattedContact]:
    contacts = event.get("event_contact_info", [])
    formatted_contacts: List[FormattedContact] = []

    for contact in contacts:
        if contact.get("public", False):
            formatted_contact: FormattedContact = {
                "name": " ".join(
                    [
                        c
                        for c in [
                            contact.get("first_name", ""),
                            contact.get("last_name", ""),
                        ]
                        if c
                    ]
                ),
                "organisation": contact.get("organisation", ""),
                "email": contact.get("contact_email", []),
                "phone": [c.get("number", "") for c in contact.get("contact_phone", []) if c.get("public")],
                "mobile": [c.get("number", "") for c in contact.get("mobile", []) if c.get("public")],
                "website": contact.get("website", ""),
            }
            formatted_contacts.append(formatted_contact)

    return formatted_contacts


def parse_date(datetime: Union[str, datetime]) -> datetime:
    """Return datetime instance for datetime."""
    if isinstance(datetime, str):
        try:
            return str_to_date(datetime)
        except ValueError:
            return arrow.get(datetime).datetime
    return datetime


def local_date(datetime: datetime, tz: pytz.BaseTzInfo) -> datetime:
    return tz.normalize(parse_date(datetime).replace(tzinfo=pytz.utc).astimezone(tz))


def time_short(datetime: datetime, tz: pytz.BaseTzInfo):
    if datetime:
        return local_date(datetime, tz).strftime(app.config.get("TIME_FORMAT_SHORT", "%H:%M"))


def date_short(datetime: datetime, tz: pytz.BaseTzInfo):
    if datetime:
        return local_date(datetime, tz).strftime(app.config.get("DATE_FORMAT_SHORT", "%d/%m/%Y"))


def get_event_formatted_dates(event: Dict[str, Any]) -> str:
    start = event.get("dates", {}).get("start")
    end = event.get("dates", {}).get("end")
    tz_name: str = event.get("dates", {}).get("tz", app.config["DEFAULT_TIMEZONE"])
    tz = pytz.timezone(tz_name)

    duration_seconds = int((end - start).total_seconds())

    if duration_seconds == ALL_DAY_SECONDS:
        # All day event
        return "{} {}".format(lazy_gettext("ALL DAY"), date_short(start, tz))

    if duration_seconds >= MULTI_DAY_SECONDS:
        # Multi day event
        return "{} {} - {} {}".format(
            time_short(start, tz), date_short(start, tz), time_short(end, tz), date_short(end, tz)
        )

    if start == end:
        # start and end are the same
        return "{} {}".format(time_short(start, tz), date_short(start, tz))

    return "{} - {}, {}".format(time_short(start, tz), time_short(end, tz), date_short(start, tz))


def update_event_item_with_translations_value(event_item: Dict[str, Any], language: str) -> Dict[str, Any]:
    if not event_item.get("translations") or not language:
        return event_item
    updated_event_item = event_item.copy()
    for translation in event_item["translations"]:
        if translation["language"] == language:
            updated_event_item[translation["field"]] = translation["value"]

    return updated_event_item
