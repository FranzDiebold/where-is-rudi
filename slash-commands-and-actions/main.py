"""Slack slash commands and actions.
"""

import os
from typing import Dict, Optional, Any, Tuple
import json
from datetime import datetime
from flask import jsonify, Response
import requests
from pytz import timezone
from google.cloud import firestore


DEFAULT_DOG_NAME = 'Rudi'
DEFAULT_TIMEZONE = 'Europe/Berlin'
FIRESTORE_COLLECTION_NAME = u'days'


SLACK_TOKEN = os.environ['SLACK_API_VERIFICATION_TOKEN']
LOCAL_TIMEZONE_STRING = os.environ.get('TIMEZONE', DEFAULT_TIMEZONE)
DOG_NAME = os.environ.get('DOG_NAME', DEFAULT_DOG_NAME)


def _verify_web_hook(form: Dict[str, Any]) -> None:
    if not form or form.get('token') != SLACK_TOKEN:
        raise ValueError('Invalid request/credentials!')


def _format_slack_message(text: str) -> Dict[str, str]:
    message = {
        'response_type': 'in_channel',
        'text': text,
    }

    return message


def _get_information() -> Optional[bool]:
    firestore_client = firestore.Client()
    day_dict = firestore_client \
        .collection(FIRESTORE_COLLECTION_NAME) \
        .document(_relevant_document_id()) \
        .get() \
        .to_dict() or {}
    return day_dict.get('in_office')


def _set_information(in_office: bool) -> None:
    firestore_client = firestore.Client()
    day_dict = {
        u'in_office': in_office
    }
    firestore_client \
        .collection(FIRESTORE_COLLECTION_NAME) \
        .document(_relevant_document_id()) \
        .set(day_dict)


def _now() -> datetime:
    local_tz = timezone(LOCAL_TIMEZONE_STRING)
    return datetime.now().astimezone(local_tz)


def _relevant_document_id() -> str:
    return _now().strftime('%Y-%m-%d')


def slash_command(request: Dict[str, Any]) -> Response:
    """Triggered from Slack slash command via an HTTPS endpoint.
    Args:
         request (dict): Request payload.
    """
    if request.method != 'POST':
        return 'Only POST requests are accepted', 405

    form = request.form

    _verify_web_hook(form)

    in_office = _get_information()
    status_to_response = {
        None: f'Hm.. I don\'t know that... :man-shrugging:',
        True: f'Yes! {DOG_NAME} :dog: is in the office today! :tada:',
        False: f'No. {DOG_NAME} is not in the office today. :disappointed:',
    }
    response = _format_slack_message(status_to_response[in_office])

    return jsonify(response)


def action(request: Dict[str, Any]) -> Tuple[str, int]:
    """Triggered from Slack action via an HTTPS endpoint.
    Args:
         request (dict): Request payload.
    """
    if request.method != 'POST':
        return 'Only POST requests are accepted', 405

    form = json.loads(request.form.get('payload', ''))

    _verify_web_hook(form)

    response_url = form.get('response_url')
    if not response_url:
        return 'No response URL!', 405

    action_to_perform = form.get('actions')[0].get('value')

    in_office = action_to_perform == 'response_yes'
    _set_information(in_office)
    today = _now().strftime('%Y-%m-%d')

    status_to_response = {
        True: f'{DOG_NAME} will be in the office today ({today}). :dog:',
        False: f'{DOG_NAME} will not be in the office today ({today}). :no_entry_sign:',
    }
    data = _format_slack_message(f'Thanks for the response!' \
        f'I noted that {status_to_response[in_office]}')
    response = requests.post(
        response_url,
        data=json.dumps(data),
        headers={'Content-Type': 'application/json'}
    )
    print(response.text)

    return '', 200
